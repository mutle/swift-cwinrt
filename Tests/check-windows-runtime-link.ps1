param(
    [Parameter(Mandatory = $true)][string]$ScratchPath,
    [Parameter(Mandatory = $true)][ValidateSet('arm64', 'x86_64')][string]$Architecture,
    [ValidateSet('native', 'swiftbuild')][string]$BuildSystem = 'native',
    [string[]]$TargetLibraryPaths = @()
)

$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'The CWinRT startup/link regression requires Windows.'
}
if (Test-Path -LiteralPath $ScratchPath) {
    throw 'Use a fresh scratch directory to rule out a previously linked CWinRT DLL.'
}
$root = Split-Path -Parent $PSScriptRoot
$swiftArchitecture = if ($Architecture -eq 'arm64') { 'aarch64' } else { $Architecture }
$arguments = @(
    '--package-path', $root, '--build-system', $BuildSystem,
    '--arch', $swiftArchitecture, '--scratch-path', $ScratchPath
)
foreach ($path in $TargetLibraryPaths) {
    $arguments += @('-Xlinker', "/LIBPATH:$path")
}

function Invoke-Swift([string[]]$Arguments) {
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & swift @Arguments
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previous }
    if ($code -ne 0) { throw "Swift command failed with exit $code" }
}

# No global SwiftCore/default-library flag: this must be a product-owned dependency.
Invoke-Swift (@('build') + $arguments + @('--product', 'CWinRT', '-v'))
$previous = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $binPath = & swift build @arguments --show-bin-path
    $binCode = $LASTEXITCODE
} finally { $ErrorActionPreference = $previous }
if ($binCode -ne 0) { throw 'Could not locate the candidate native CWinRT output.' }
$dll = Join-Path $binPath 'CWinRT.dll'
if (-not (Test-Path -LiteralPath $dll)) { throw 'The CWinRT product DLL was not built.' }

$triple = if ($Architecture -eq 'arm64') {
    'aarch64-unknown-windows-msvc'
} else { 'x86_64-unknown-windows-msvc' }
$probe = Join-Path $ScratchPath 'LoadCWinRT.exe'
$probeLinks = @()
foreach ($path in $TargetLibraryPaths) { $probeLinks += @('-L', $path) }
$previous = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    & swiftc -target $triple @probeLinks (Join-Path $PSScriptRoot 'Fixtures\LoadCWinRT.swift') -o $probe
    $probeCode = $LASTEXITCODE
} finally { $ErrorActionPreference = $previous }
if ($probeCode -ne 0) { throw 'The architecture-matched DLL load probe did not compile.' }
for ($run = 0; $run -lt 3; ++$run) {
    & $probe $dll
    if ($LASTEXITCODE -ne 0) { throw 'The candidate CWinRT DLL did not load and unload.' }
}
Write-Output 'CWINRT_NATIVE_DLL_LOAD=PASSED'
Invoke-Swift (@('test') + $arguments + @('--filter', 'CWinRTTests'))
Write-Output 'CWINRT_SWIFT_CONSUMER_REGISTRATION=PASSED'
