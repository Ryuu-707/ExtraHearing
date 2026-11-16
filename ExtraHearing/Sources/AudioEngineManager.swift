import Foundation
import AVFoundation

final class AudioEngineManager: ObservableObject {
    private let engine = AVAudioEngine()
    private let intermediateMixer = AVAudioMixerNode()
    private let eqNode = AVAudioUnitEQ(numberOfBands: 2)
    
    @Published var isRunning = false
    @Published var isLocalMuted = false
    @Published var isEQEnabled = true {
        didSet {
            eqNode.bypass = !isEQEnabled
        }
    }
    
    // Amplification from 0.0 (0%) to 1.0 (100%)
    @Published var amplification: Double = 0.5 {
        didSet {
            updateAudioParameters()
        }
    }
    
    init() {
        setupAudioSession()
        setupEngine()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setPreferredSampleRate(48000)
            try session.setPreferredIOBufferDuration(0.005) // Low latency
            try session.setActive(true)
        } catch {
            print("Failed to configure AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    private func setupEngine() {
        // Attach custom nodes
        engine.attach(intermediateMixer)
        engine.attach(eqNode)
        
        // Configure Equalizer Bands
        // Band 0: High-Pass filter at 100 Hz for low-frequency rumble reduction
        let band0 = eqNode.bands[0]
        band0.filterType = .highPass
        band0.frequency = 100
        band0.bypass = false
        
        // Band 1: Parametric filter at 2000 Hz for speech clarity
        let band1 = eqNode.bands[1]
        band1.filterType = .parametric
        band1.frequency = 2000
        band1.bandwidth = 1.8
        band1.bypass = false
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // Ensure valid format for connections
        let sampleRate = inputFormat.sampleRate > 0 ? inputFormat.sampleRate : 48000
        let channelCount = inputFormat.channelCount > 0 ? inputFormat.channelCount : 1
        let processingFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: channelCount, interleaved: false)
        
        // Signal Path: inputNode -> intermediateMixer -> eqNode -> mainMixerNode
        engine.connect(inputNode, to: intermediateMixer, format: processingFormat)
        engine.connect(intermediateMixer, to: eqNode, format: processingFormat)
        engine.connect(eqNode, to: engine.mainMixerNode, format: processingFormat)
        
        updateAudioParameters()
    }
    
    func toggleEngine() {
        if isRunning {
            stopEngine()
        } else {
            startEngine()
        }
    }
    
    func startEngine() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            if !engine.isRunning {
                try engine.start()
            }
            isRunning = true
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }
    }
    
    func stopEngine() {
        engine.stop()
        isRunning = false
    }
    
    func toggleLocalMute() {
        isLocalMuted.toggle()
        updateAudioParameters()
    }
    
    func toggleEQ() {
        isEQEnabled.toggle()
    }
    
    private func updateAudioParameters() {
        let amp = Float(amplification)
        
        // 1. intermediateMixer Volume (scaled up to 4.0x)
        if isLocalMuted {
            intermediateMixer.outputVolume = 0.0
        } else {
            // Smooth scaling from 0.0 to 4.0x
            intermediateMixer.outputVolume = amp * 4.0
        }
        
        // 2. Global Gain up to +24 dB
        eqNode.globalGain = amp * 24.0
        
        // 3. Band 1 parametric boost up to +18 dB
        if eqNode.bands.count > 1 {
            eqNode.bands[1].gain = amp * 18.0
        }
    }
}
