import XCTest
@testable import Rizzr

final class RizzrModeTests: XCTestCase {
    func testFinesseIsOnlyEnabledProductionMode() {
        let flags = AppFeatureFlags.production

        XCTAssertTrue(flags.isEnabled(.finesse))
        XCTAssertFalse(flags.isEnabled(.ghost))
        XCTAssertFalse(flags.isEnabled(.echo))
        XCTAssertFalse(flags.isEnabled(.vibe))
    }

    func testModesHaveUserFacingCopy() {
        for mode in RizzrMode.allCases {
            XCTAssertFalse(mode.title.isEmpty)
            XCTAssertFalse(mode.headline.isEmpty)
            XCTAssertFalse(mode.description.isEmpty)
        }
    }

    func testModeFeatureGatesMatchModeIdentity() {
        XCTAssertEqual(RizzrMode.finesse.featureGate, .finesse)
        XCTAssertEqual(RizzrMode.ghost.featureGate, .ghost)
        XCTAssertEqual(RizzrMode.echo.featureGate, .echo)
        XCTAssertEqual(RizzrMode.vibe.featureGate, .vibe)
    }
}
