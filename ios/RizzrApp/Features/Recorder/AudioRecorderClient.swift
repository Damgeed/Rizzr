import AVFoundation
import Foundation

protocol AudioRecorderClient: AnyObject {
    func requestPermission() async -> Bool
    func startRecording() async throws
    func stopRecording() async throws -> RecordingSession
}

enum AudioRecorderError: LocalizedError, Equatable {
    case permissionDenied
    case recorderUnavailable
    case noActiveRecording
    case recordingTooShort
    case recordingTooLong

    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Microphone permission is required to record a voice note."
        case .recorderUnavailable: "The recorder could not be started."
        case .noActiveRecording: "There is no active recording to stop."
        case .recordingTooShort: "That voice note was too short. Record at least one second."
        case .recordingTooLong: "Keep voice notes under two minutes for now."
        }
    }
}

final class AVAudioRecorderClient: NSObject, AudioRecorderClient, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private var activeURL: URL?
    private var startedAt: Date?
    private let clock: ClockClient

    init(clock: ClockClient = SystemClockClient()) {
        self.clock = clock
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }

    func startRecording() async throws {
        guard await requestPermission() else { throw AudioRecorderError.permissionDenied }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true

        guard recorder.record() else { throw AudioRecorderError.recorderUnavailable }
        self.recorder = recorder
        activeURL = url
        startedAt = clock.now
    }

    func stopRecording() async throws -> RecordingSession {
        guard let recorder, let activeURL, let startedAt else { throw AudioRecorderError.noActiveRecording }
        recorder.stop()
        self.recorder = nil
        self.activeURL = nil
        self.startedAt = nil
        try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        let recording = RecordingSession(url: activeURL, duration: clock.now.timeIntervalSince(startedAt), createdAt: clock.now)
        guard recording.isLongEnoughForProcessing else { throw AudioRecorderError.recordingTooShort }
        guard recording.isWithinSupportedLength else { throw AudioRecorderError.recordingTooLong }
        return recording
    }
}
