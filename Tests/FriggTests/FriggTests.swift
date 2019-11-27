import XCTest
@testable import Frigg

final class FriggTests: XCTestCase {
    let subject = Frigg()
    func testExample() {
        let expectation = XCTestExpectation(description: "example")
        
        let _ = subject.parse("https://en.wikipedia.org/wiki/Frigg")?
        .assertNoFailure()
        .receive(on: RunLoop.main)
        .sink {
            XCTAssertEqual($0.title, "Frigg - Wikipedia")
            XCTAssertEqual($0.imageURL, URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/2f/Frigg_by_Doepler.jpg"))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
