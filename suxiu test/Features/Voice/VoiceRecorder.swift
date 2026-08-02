import Foundation
import Combine
import AVFoundation
import Speech
#if os(iOS)
import UIKit
#endif

/// 语音录制器 - 处理语音录制和语音转文字
///
/// 功能：
/// - 录制音频
/// - 实时语音转文字
/// - 返回转写文本用于 AI 图片生成
class VoiceRecorder: NSObject, ObservableObject {
    /// 是否正在录音
    @Published var isRecording = false

    /// 录音时长（秒）
    @Published var recordingDuration: Double = 0

    /// 转写的文本
    @Published var transcribedText: String = ""

    /// 音频录音机
    private var audioRecorder: AVAudioRecorder?

    /// 语音识别器
    private var speechRecognizer: SFSpeechRecognizer?

    /// 语音识别请求
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    /// 语音识别任务
    private var recognitionTask: SFSpeechRecognitionTask?

    /// 音频引擎
    private var audioEngine: AVAudioEngine?

    /// 临时音频文件 URL
    private var tempAudioURL: URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
    }

    /// 检查语音识别权限
    static func checkPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// 检查麦克风权限
    static func checkMicrophonePermission() async -> Bool {
#if os(iOS)
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                return true
            case .denied:
                return false
            case .undetermined:
                return await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            @unknown default:
                return false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                return true
            case .denied:
                return false
            case .undetermined:
                return await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
            @unknown default:
                return false
            }
        }
#else
        return true
#endif
    }

    /// 开始录音
    func startRecording() {
        do {
#if os(iOS)
            // 检查麦克风权限
            let hasPermission: Bool
            if #available(iOS 17.0, *) {
                hasPermission = AVAudioApplication.shared.recordPermission == .granted
            } else {
                hasPermission = AVAudioSession.sharedInstance().recordPermission == .granted
            }

            if !hasPermission {
                return
            }

            // 配置音频会话
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
#endif
            // 设置音频格式
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            // 创建录音机
            audioRecorder = try AVAudioRecorder(url: tempAudioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            // 开始语音识别
            startSpeechRecognition()

            isRecording = true
            recordingDuration = 0

            // 更新录音时长
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                if !self.isRecording {
                    timer.invalidate()
                    return
                }
                self.recordingDuration += 0.1
            }

        } catch {
            print("录音失败：\(error)")
        }
    }

    /// 停止录音
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil

        stopSpeechRecognition()

        isRecording = false
    }

    /// 开始语音识别
    private func startSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))

        guard let recognizer = speechRecognizer else {
            print("无法创建语音识别器")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            print("无法创建识别请求")
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                print("语音识别错误：\(error)")
                return
            }

            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
            }

            if result?.isFinal ?? false || error != nil {
                self.stopSpeechRecognition()
            }
        }

        // 配置音频引擎用于实时识别
        setupAudioEngine()
    }

    /// 停止语音识别
    private func stopSpeechRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        audioEngine?.stop()
        audioEngine = nil
    }

    /// 配置音频引擎
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()

        let audioNode = audioEngine?.inputNode
        let recordingFormat = audioNode?.outputFormat(forBus: 0)

        audioNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        try? audioEngine?.start()
    }

    /// 获取录音文本（用于 AI 生成）
    func getTranscribedText() -> String {
        return transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("录音未能成功完成")
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("录音编码错误：\(error)")
        }
    }
}
