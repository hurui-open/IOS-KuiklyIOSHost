import XCTest
@testable import KuiklyIOSHost

final class KuiklyIOSHostTests: XCTestCase {
    func testPackageLoadsDefaultConfiguration() {
        XCTAssertEqual(KuiklyHostSupportConfiguration.currentConfiguration().contextCode, "Shared")
    }
}
