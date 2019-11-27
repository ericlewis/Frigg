import XCTest
@testable import Frigg

final class FriggTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Frigg().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
