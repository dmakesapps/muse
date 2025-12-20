import Foundation
import Speech
import AVFoundation

/// Service for Speech-to-Text (Voice Recognition)
/// Uses Apple's native SFSpeechRecognizer
class SpeechRecognizer: NSObject, ObservableObject {
    static let shared = SpeechRecognizer()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var error: String?
    @Published var isAuthorized = false
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.isAuthorized = true
                    print("🎤 SpeechRecognizer: Authorized")
                case .denied:
                    self?.isAuthorized = false
                    self?.error = "Speech recognition permission denied"
                    print("🚫 SpeechRecognizer: Denied")
                case .restricted:
                    self?.isAuthorized = false
                    self?.error = "Speech recognition restricted on this device"
                    print("🚫 SpeechRecognizer: Restricted")
                case .notDetermined:
                    self?.isAuthorized = false
                    print("❓ SpeechRecognizer: Not Determined")
                @unknown default:
                    self?.isAuthorized = false
                }
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private var silenceTimer: Timer?
    
    func startRecording() {
        // Cancel any existing task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Reset timer
        silenceTimer?.invalidate()
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Use playAndRecord to allow simultaneous recording and playback (background music).
            // .duckOthers reduced volume of background music while listening, which is nice for voice interaction.
            // .defaultToSpeaker ensures output doesn't switch to the localized earpiece.
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "Audio session failed setup"
            print("❌ SpeechRecognizer: Audio session setup error: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            self.error = "Unable to create recognition request"
            return
        }
        
        // Disable partial results if you only want final text, 
        // but for chat, seeing it type in real-time is nice.
        recognitionRequest.shouldReportPartialResults = true
        
        // Microphone input format
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        engineStart()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                    
                    // Reset silence timer on every new result
                    self.resetSilenceTimer()
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.silenceTimer?.invalidate() // Stop timer
                
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
        
        DispatchQueue.main.async {
            self.isRecording = true
            self.transcript = "" // Reset transcript for new recording
            self.error = nil // Clear errors
        }
        
        print("🎤 SpeechRecognizer: Started recording")
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            print("🤫 SpeechRecognizer: Silence detected, stopping recording...")
            self?.stopRecording()
        }
    }
    
    private func engineStart() {
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("❌ SpeechRecognizer: Audio engine start error: \(error)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
        print("🛑 SpeechRecognizer: Stopped recording")
        
        // Reset audio session to playback with mixing to restore full volume to background music
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
