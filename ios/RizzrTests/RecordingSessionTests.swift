import XCTest
@testable import Rizzr

final class RecordingSessionTests: XCTestCase {
    func testRecordingDurationPolicyRejectsSubSecondAudio() {
        let recording = RecordingSession(
            url: URL(fileURLWithPath: "/tmp/short.m4a"),
            duration: 0.4,
            createdAt: Date()
        )

        XCTAssertFalse(recording.isLongEnoughForProcessing)
        XCTAssertTrue(recording.isWithinSupportedLength)
    }

    func testRecordingDurationPolicyAllowsReasonableAudio() {
        let recording = RecordingSession(
            url: URL(fileURLWithPath: "/tmp/valid.m4a"),
            duration: 12.0,
            createdAt: Date()
        )

        XCTAssertTrue(recording.isLongEnoughForProcessing)
        XCTAssertTrue(recording.isWithinSupportedLength)
    }

    func testRecordingDurationPolicyRejectsOverTwoMinutes() {
        let recording = RecordingSession(
            url: URL(fileURLWithPath: "/tmp/long.m4a"),
            duration: 121.0,
            createdAt: Date()
        )

        XCTAssertTrue(recording.isLongEnoughForProcessing)
        XCTAssertFalse(recording.isWithinSupportedLength)
    }
}
