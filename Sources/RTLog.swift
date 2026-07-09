import Foundation
import AppKit
import Combine

/// Ring-buffer + file logger for diagnose Wi‑Fi join / kext OID path.
final class RTLog: ObservableObject {
    static let shared = RTLog()

    static let filePath = NSHomeDirectory() + "/Library/Logs/RTLWifiTahoe.log"
    private let maxLines = 400
    private let maxFileSize: UInt64 = 1_000_000 // 1 MB
    private let lock = NSLock()
    private var lines: [String] = []
    private var writeBuffer: [String] = []
    private var flushTimer: DispatchSourceTimer?

    @Published private(set) var recentText: String = ""

    private init() {
        rotateIfNeeded()
        truncateIfNeeded()
        startFlushTimer()
        log("——— session start \(ISO8601DateFormatter().string(from: Date())) ———")
    }

    func log(_ message: String) {
        let ts = Self.stamp()
        let line = "[\(ts)] \(message)"
        lock.lock()
        lines.append(line)
        if lines.count > maxLines {
            lines.removeFirst(lines.count - maxLines)
        }
        let snapshot = lines.suffix(80).joined(separator: "\n")
        writeBuffer.append(line)
        let shouldFlush = writeBuffer.count >= 50
        lock.unlock()

        #if DEBUG
        print(line)
        #endif

        if shouldFlush { flush() }

        DispatchQueue.main.async { [weak self] in
            self?.recentText = snapshot
        }
    }

    private func startFlushTimer() {
        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.flush()
        }
        timer.resume()
        flushTimer = timer
    }

    private func flush() {
        lock.lock()
        guard !writeBuffer.isEmpty else {
            lock.unlock()
            return
        }
        let toWrite = writeBuffer.joined(separator: "\n") + "\n"
        writeBuffer.removeAll()
        lock.unlock()

        let data = toWrite.data(using: .utf8) ?? Data()
        if !FileManager.default.fileExists(atPath: Self.filePath) {
            FileManager.default.createFile(atPath: Self.filePath, contents: data)
        } else if let h = try? FileHandle(forWritingTo: URL(fileURLWithPath: Self.filePath)) {
            defer { try? h.close() }
            h.seekToEndOfFile()
            h.write(data)
        }

        rotateIfNeeded()
    }

    /// If file > maxFileSize, rotate: .log → .1.log, start fresh.
    private func rotateIfNeeded() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: Self.filePath),
              let size = attrs[.size] as? UInt64, size > maxFileSize else { return }
        let rotated = Self.filePath + ".1"
        try? FileManager.default.removeItem(atPath: rotated)
        try? FileManager.default.moveItem(atPath: Self.filePath, toPath: rotated)
        // Avoid recursive log() → flush → rotate storms: write one line without buffering
        let note = "[\(Self.stamp())] log rotated (\(size) bytes → .1.log)\n"
        if let d = note.data(using: .utf8) {
            FileManager.default.createFile(atPath: Self.filePath, contents: d)
        }
    }

    /// If file > 5MB even after rotation, truncate to empty.
    private func truncateIfNeeded() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: Self.filePath),
              let size = attrs[.size] as? UInt64, size > 5_000_000 else { return }
        try? "".write(toFile: Self.filePath, atomically: true, encoding: .utf8)
    }

    func section(_ title: String) {
        log("==== \(title) ====")
    }

    func clear() {
        lock.lock()
        lines.removeAll()
        writeBuffer.removeAll()
        lock.unlock()
        try? "".write(toFile: Self.filePath, atomically: true, encoding: .utf8)
        DispatchQueue.main.async { self.recentText = "" }
        log("log cleared")
    }

    func copyToPasteboard() {
        flush()
        lock.lock()
        let all = lines.joined(separator: "\n")
        lock.unlock()
        let file = (try? String(contentsOfFile: Self.filePath, encoding: .utf8)) ?? all
        let text = file.count > all.count ? file : all
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        log("copied \(text.split(separator: "\n").count) lines to clipboard")
    }

    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: Self.filePath)])
    }

    private static func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: Date())
    }
}

func rtlog(_ msg: String) {
    RTLog.shared.log(msg)
}
