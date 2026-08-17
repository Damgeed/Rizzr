import Foundation

protocol ClockClient {
    var now: Date { get }
}

struct SystemClockClient: ClockClient {
    var now: Date { Date() }
}

struct RecordingSession: Equatable {
    enum DurationPolicy {
        static let minimumUsefulDuration: TimeInterval = 1.0
        static let maximumSupportedDuration: TimeInterval = 120.0
    }

    let url: URL
    let duration: TimeInterval
    let createdAt: Date

    var isLongEnoughForProcessing: Bool {
        duration >= DurationPolicy.minimumUsefulDuration
    }

    var isWithinSupportedLength: Bool {
        duration <= DurationPolicy.maximumSupportedDuration
    }
}
