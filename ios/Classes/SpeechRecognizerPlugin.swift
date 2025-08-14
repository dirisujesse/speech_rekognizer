import Flutter
import Speech
import UIKit

public class SpeechRecognizerPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.dirisujesse.speech_recognizer/methods",
            binaryMessenger: registrar.messenger())
        let instance = SpeechRecognizerPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startTranscription":
            guard let args = call.arguments as? [String: Any],
                let localeIdentifier = args["locale"] as? String?
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS", message: "Locale argument is missing or invalid",
                        details: nil))
                return
            }
            self.startTranscription(localeIdentifier: localeIdentifier, result: result)
        case "stopTranscription":
            self.stopTranscription(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startTranscription(localeIdentifier: String?, result: @escaping FlutterResult) {
        // Stop any previous tasks before starting a new one.
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // --- 1. Request Authorization ---
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.setupAndStartRecognition(
                        localeIdentifier: localeIdentifier, result: result)
                case .denied, .restricted, .notDetermined:
                    let errorMessage = "Speech recognition authorization was denied."
                    DispatchQueue.main.async {
                        self.channel.invokeMethod("onSpeechError", arguments: errorMessage)
                        result(
                            FlutterError(
                                code: "AUTH_STATUS_DENIED", message: errorMessage, details: nil))
                    }
                @unknown default:
                    DispatchQueue.main.async {
                        result(
                            FlutterError(
                                code: "UNKNOWN_AUTH_STATUS",
                                message: "Unknown authorization status", details: nil))
                    }
                }
            }
        }
    }

    private func setupAndStartRecognition(
        localeIdentifier: String?, result: @escaping FlutterResult
    ) {
        // --- 2. Setup Recognizer ---
        let finalLocaleId = localeIdentifier ?? "hr-HR"  // Default to Croatian
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: finalLocaleId)) else {
            let errorMessage = "Speech recognizer is not supported for \(finalLocaleId)."
            DispatchQueue.main.async {
                self.channel.invokeMethod("onSpeechError", arguments: errorMessage)
                result(
                    FlutterError(
                        code: "RECOGNIZER_UNAVAILABLE", message: errorMessage, details: nil))
            }
            return
        }
        self.speechRecognizer = recognizer

        // --- 3. Setup Audio Session ---
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            let errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
            DispatchQueue.main.async {
                self.channel.invokeMethod("onSpeechError", arguments: errorMessage)
                result(
                    FlutterError(code: "AUDIO_SESSION_ERROR", message: errorMessage, details: nil))
            }
            return
        }

        // --- 4. Setup Recognition Request ---
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            let errorMessage = "Unable to create an SFSpeechAudioBufferRecognitionRequest object"
            DispatchQueue.main.async {
                self.channel.invokeMethod("onSpeechError", arguments: errorMessage)
                result(
                    FlutterError(
                        code: "RECOGNITION_REQUEST_ERROR", message: errorMessage, details: nil))
            }
            return
        }
        recognitionRequest.shouldReportPartialResults = true

        // --- 5. Start Recognition Task ---
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) {
            [weak self] taskResult, error in
            var isFinal = false

            if let taskResult = taskResult {
                isFinal = taskResult.isFinal

                guard !isFinal else {
                    result(nil)
                    self?.stopTranscription(result)
                    return
                }

                DispatchQueue.main.async {
                    let text = taskResult.bestTranscription.formattedString ?? ""
                    self?.channel.invokeMethod("onPartialSpeechResult", arguments: text)
                }
            }

            if error != nil || isFinal {
                self?.stopTranscription(result)
            }
        }

        // --- 6. Start Audio Engine ---
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        // Remove any existing tap before installing a new one
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [weak self] (buffer, when) in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.channel.invokeMethod("onSpeechReady", arguments: true)
            }
        } catch {
            let errorMessage = "Audio engine failed to start: \(error.localizedDescription)"
            DispatchQueue.main.async {
                self.channel.invokeMethod("onSpeechError", arguments: errorMessage)
                result(
                    FlutterError(code: "AUDIO_ENGINE_ERROR", message: errorMessage, details: nil))
            }
        }
    }

    private func stopTranscription(_ result: @escaping FlutterResult) {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        speechRecognizer = nil

        result(nil)  // Successfully stopped
    }
}
