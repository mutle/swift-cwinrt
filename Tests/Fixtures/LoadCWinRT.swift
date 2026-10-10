#if os(Windows)
import Foundation
import WinSDK

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("Expected the candidate CWinRT DLL path.\n".utf8))
    ExitProcess(1)
}
let path = CommandLine.arguments[1]
let (module, loadError) = path.withCString(encodedAs: UTF16.self) {
    let module = LoadLibraryExW($0, nil, DWORD(0x1100))
    return (module, module == nil ? GetLastError() : DWORD(0))
}
guard let module else {
    FileHandle.standardError.write(Data("LoadLibraryExW failed: \(loadError)\n".utf8))
    ExitProcess(1)
}
guard FreeLibrary(module) else {
    FileHandle.standardError.write(Data("FreeLibrary failed: \(GetLastError())\n".utf8))
    ExitProcess(1)
}
print("CWINRT_LOAD_AND_UNLOAD=PASSED")
#else
fatalError("LoadCWinRT requires Windows")
#endif
