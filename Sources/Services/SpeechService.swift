import Foundation
import Speech
import AVFoundation

final class SpeechService: ObservableObject {
    static let shared = SpeechService()

    @Published var isRecording: Bool = false
    @Published var transcript: String = ""
    @Published var errorMessage: String?

    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }

    func startRecording(onTextRecognized: @escaping (String) -> Void) {
        guard !isRecording else { return }

        // Cancel any pending task
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = audioSession.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioSession.prepare()
        do {
            try audioSession.start()
        } catch {
            self.errorMessage = "Audio engine could not start: \(error.localizedDescription)"
            return
        }

        self.recognitionRequest = request
        self.isRecording = true

        self.recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let spoken = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcript = spoken
                    onTextRecognized(spoken)
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                self.stopRecording()
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
}
