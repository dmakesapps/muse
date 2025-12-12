import SwiftUI
import Speech
import AVFoundation

struct MultimodalInputView: View {
    @Binding var input: String
    let isDarkMode: Bool
    var onSubmit: () -> Void
    @FocusState private var isFocused: Bool
    @State private var isRecording = false
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Text input area - use TextField for thin single-line input
            TextField("What would you like to do?", text: $input, axis: .vertical)
                .foregroundColor(isDarkMode ? Color.white : Color.black)
                .font(.system(size: 16))
                .focused($isFocused)
                .lineLimit(1...5) // Allow up to 5 lines, starts as 1 line
                .textFieldStyle(.plain)
                .padding(.leading, 12)
            
            // Right side icons (microphone and send)
            HStack(spacing: 12) {
                Button {
                    if isRecording {
                        speechRecognizer.stopRecording()
                        isRecording = false
                    } else {
                        speechRecognizer.startRecording { transcript in
                            input = transcript
                        }
                        isRecording = true
                    }
                } label: {
                    Image(systemName: isRecording ? "mic.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isRecording ? Color.red : (isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.7)))
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isRecording)
                }
                
                Button(action: onSubmit) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(input.isEmpty ? (isDarkMode ? Color.white.opacity(0.4) : Color.black.opacity(0.4)) : Color.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(input.isEmpty ? Color.clear : Color.themeAccent)
                        )
                }
                .disabled(input.isEmpty)
            }
            .padding(.trailing, 12)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
        )
        .frame(maxWidth: 600) // Thin width like Claude
        .onDisappear {
            if isRecording {
                speechRecognizer.stopRecording()
                isRecording = false
            }
        }
    }
}

// MARK: - Speech Recognizer
class SpeechRecognizer: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    var onTranscriptUpdate: ((String) -> Void)?
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // Authorization requested
        }
    }
    
    func startRecording(onTranscriptUpdate: @escaping (String) -> Void) {
        self.onTranscriptUpdate = onTranscriptUpdate
        
        // Cancel previous task if any
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }
        
        // Create recognition request
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            return
        }
        
        // Start recognition
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcript = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.onTranscriptUpdate?(transcript)
                }
                
                if result.isFinal {
                    self.stopRecording()
                }
            }
            
            if error != nil {
                self.stopRecording()
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}


