import CWinRT
import XCTest

#if os(Windows)
private let windowsAPIType: GUID_Workaround.Type = GUID_Workaround.self

private protocol RegistrationValue: Sendable {
    var value: Int { get }
}

private struct PrivateRegistrationValue: RegistrationValue {
    let value: Int
}

private actor RegistrationActor<Value: RegistrationValue> {
    private let payload: Value

    init(_ payload: Value) {
        self.payload = payload
    }

    func read() -> Int {
        payload.value
    }
}
#endif

final class CWinRTTests: XCTestCase {
    func testModuleImports() {}

    #if os(Windows)
    func testGenericActorWithPrivateConformer() async {
        // Resolve concrete actor metadata in the consuming Swift image, not just C imports.
        let actor = RegistrationActor(PrivateRegistrationValue(value: 42))
        let value = await actor.read()
        XCTAssertEqual(value, 42)
    }
    #endif
}
