#!/usr/bin/env swift
import Foundation
import AVFoundation
import Darwin

// ============================================================================
// CONFIGURATION
// ============================================================================

let LOUD_THRESHOLD: Float = -20.0
let BAR_LENGTH: Int = 50

// ============================================================================
// Microphone Volume Monitor
// ============================================================================

class MicrophoneMonitor {
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    
    private let green = "\u{001B}[92m"
    private let red = "\u{001B}[91m"
    private let reset = "\u{001B}[0m"
    private let bold = "\u{001B}[1m"
    private let clearLine = "\u{001B}[2K"
    
    private var lastDeviceID: AudioDeviceID = 0
    private var deviceCheckTimer: Timer?
    
    init() {
        setupAudioEngine()
        startDeviceMonitoring()
    }
    
    private func setupAudioEngine() {
        // Stop old engine if running
        if audioEngine?.isRunning ?? false {
            audioEngine?.stop()
            inputNode?.removeTap(onBus: 0)
        }
        
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    private func startDeviceMonitoring() {
        // Check for device changes every 1 second
        deviceCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForDeviceChange()
        }
    }
    
    private func checkForDeviceChange() {
        let currentDevice = getDefaultInputDevice()
        
        if lastDeviceID == 0 {
            lastDeviceID = currentDevice
        } else if currentDevice != lastDeviceID {
            lastDeviceID = currentDevice
            // Device changed, restart audio engine
            DispatchQueue.main.async {
                self.setupAudioEngine()
                self.showDeviceChange()
            }
        }
    }
    
    private func getDefaultInputDevice() -> AudioDeviceID {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &size,
            &deviceID
        )
        
        return status == noErr ? deviceID : 0
    }
    
    private func showDeviceChange() {
        let msg = "\r\(clearLine)🔄 Microphone changed - reconnected\n"
        if let data = msg.data(using: .utf8) {
            let bytes = (data as NSData).bytes
            _ = Darwin.write(STDOUT_FILENO, bytes, data.count)
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataPointer = channelData[0]
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0.0
        for i in 0..<frameLength {
            let sample = channelDataPointer[i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frameLength))
        let db = 20 * log10(rms)
        
        let isLoud = db > LOUD_THRESHOLD
        
        drawBar(db: db, isLoud: isLoud)
    }
    
    private func drawBar(db: Float, isLoud: Bool) {
        let normalizedVolume = max(0, min(1, (db + 60) / 50))
        let filledLength = Int(Float(BAR_LENGTH) * normalizedVolume)
        let emptyLength = BAR_LENGTH - filledLength
        
        let color = isLoud ? red : green
        let status = isLoud ? "\(bold)\(red)TOO LOUD!\(reset)" : "\(green)Normal volume\(reset)"
        
        let bar = color + String(repeating: "█", count: filledLength) + String(repeating: "░", count: emptyLength) + reset
        
        let dbValue = String(format: "%.1f dB", db)
        let line = "\r\(clearLine)[\(bar)] \(dbValue) | \(status)"
        
        if let data = line.data(using: .utf8) {
            let bytes = (data as NSData).bytes
            _ = Darwin.write(STDOUT_FILENO, bytes, data.count)
        }
    }
    
    func start() throws {
        print("🎤 Microphone Volume Monitor")
        print(String(repeating: "=", count: 70))
        print("Green = Normal speaking volume")
        print("Red = Too loud (>= \(Int(-LOUD_THRESHOLD)) dB)")
        print("✓ Auto-reconnects if microphone changes")
        print(String(repeating: "=", count: 70))
        print("Press Ctrl+C to stop\n")
        
        print("✓ Microphone connected and monitoring...\n")
        
        RunLoop.main.run()
    }
}

let monitor = MicrophoneMonitor()

signal(SIGINT) { _ in
    print("\n\nStopped.")
    exit(0)
}

do {
    try monitor.start()
} catch {
    print("Error: \(error)")
}
