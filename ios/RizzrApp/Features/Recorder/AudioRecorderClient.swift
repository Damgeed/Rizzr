import AVFoundation
import Foundation

protocol AudioRecorderClient: AnyObject {
    func requestPermission() async -> Bool
    func startRecording() async throws
    func stopRecording() async throws -> URL
}

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case recorderUnavailable
    case noActiveRecording

    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Microphone permission is required to record a voice note."
        case .recorderUnavailable: "The recorder could not be started."
        case .noActiveRecording: "There is no active recording to stop."
        }
    }
}

final class AVAudioRecorderClient: NSObject, AudioRecorderClient, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private var activeURL: URL?

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
    }

    func stopRecording() async throws -> URL {
        guard let recorder, let activeURL else { throw AudioRecorderError.noActiveRecording }
        recorder.stop()
        self.recorder = nil
        self.activeURL = nil
        try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return activeURL
    }
}
