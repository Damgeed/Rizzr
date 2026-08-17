import XCTest
@testable import Rizzr

final class RizzrModeTests: XCTestCase {
    func testFinesseIsOnlyLiveMode() {
        XCTAssertTrue(RizzrMode.finesse.isLive)
        XCTAssertFalse(RizzrMode.ghost.isLive)
        XCTAssertFalse(RizzrMode.echo.isLive)
        XCTAssertFalse(RizzrMode.vibe.isLive)
    }

    func testModesHaveUserFacingCopy() {
        for mode in RizzrMode.allCases {
            XCTAssertFalse(mode.title.isEmpty)
            XCTAssertFalse(mode.headline.isEmpty)
            XCTAssertFalse(mode.description.isEmpty)
        }
    }
}
