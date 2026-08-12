import CWinRT
import XCTest

#if os(Windows)
private let windowsAPIType: GUID_Workaround.Type = GUID_Workaround.self
#endif

final class CWinRTTests: XCTestCase {
    func testModuleImports() {}
}
