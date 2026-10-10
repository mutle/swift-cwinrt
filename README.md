# swift-cwinrt

> [!WARNING]
> This project contains an outdated snapshot of a subset of WinRT projections generated with [swift-winrt](https://github.com/thebrowsercompany/swift-winrt), provided for illustration purposes. To use WinRT APIs in your Swift project, we recommend using [swift-winrt](https://github.com/thebrowsercompany/swift-winrt) directly to generate your own projections.

C API definition used by Swift Language bindings.

This project references all metadata files uses by the various swift-* projects. The CWinRT contains the C ABI definitions for all types that can be used.

On Windows, the `CWinRT` module exposes the generated WinRT C API. On other
platforms, the same product and target remain available as an empty module so
cross-platform Swift packages can depend on it without requiring Windows SDK
headers.

The product remains a dynamic library and uses the toolchain's normal startup
files. Do not add `-nostartfiles` to its target linker settings: SwiftPM can
propagate those settings to Swift consumers. On Windows this suppresses
`swiftrt.obj`, preventing Swift DLL metadata registration and potentially crashing
generic type or actor instantiation.

The Windows target explicitly links `swiftCore`, the import library required by
`swiftrt.obj`'s `swift_addNewDSOImage` registration entry point. This keeps a
C-only dynamic product linkable with the native SwiftPM backend without a
consumer-wide `/defaultlib:swiftCore.lib` workaround. The dependency is
Windows-only; the package graph and non-Windows compatibility module are unchanged.

## Regression checks

Run `python3 Tests/PackageManifestTests.py` for the lightweight source contract
(no startup suppression and an explicitly dynamic product). This does not build
or load either library.

Run `swift test --filter CWinRTTests` for the import test and, on Windows, the
generic actor/private protocol conformer runtime test. The latter must execute,
not merely compile, in the consuming Swift test image. It uses XCTest and
requires no newer test framework than the package's Swift 5.10 tools baseline.
Non-Windows platforms retain the empty-module import test.

For a Windows linker change, also build the `CWinRT` product itself
(`swift build --product CWinRT`) and explicitly load the resulting DLL; the Swift
test alone does not establish that the C library links and loads correctly.
With Swift 6.4's default SwiftBuild backend, inspect the generated build plan for
exported startup suppression and verify the Swift consumer's expanded driver
job includes the SDK's architecture-matched `swiftrt.obj`. Check the final Swift
DLL's registration support and execute the runtime test in fresh processes.
Use a separate `--scratch-path` for isolated verification rather than reusing
the historical build artifacts tracked in this repository.

`Tests/check-windows-runtime-link.ps1` builds the dynamic product from a fresh
scratch directory, compiles an architecture-matched load probe, loads/unloads
the candidate DLL in three fresh processes, and runs the Swift consumer tests.
For example, in a configured Windows compiler/runtime environment:

```powershell
.\Tests\check-windows-runtime-link.ps1 `
    -ScratchPath C:\isolated\cwinrt-native-new-run `
    -Architecture x86_64 -BuildSystem native
```

Use `arm64` for an ARM64 target and `swiftbuild` to check the default backend.
On a cross-architecture host, pass the installed target MSVC and Windows SDK
library directories through `-TargetLibraryPaths`; these must not replace the
host manifest compiler's library environment. No global SwiftCore or startup
suppression flag is added by the driver. Preserve the verbose product linker
command to confirm both the target's SwiftCore import and its architecture-matched
`swiftrt.obj`.
