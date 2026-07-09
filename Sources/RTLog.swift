import Foundation
import AppKit
import Combine

/// Ring-buffer + file logger for diagnose Wi‑Fi join / kext OID path.
final class RTLog: ObservableObject {
    static let shared = RTLog()

    static let filePath = NSHomeDirectory() + "/Library/Logs/RTLWifiTahoe.log"
    private let maxLines = 400
    private let lock = NSLock()
    private var lines: [String] = []

    @Published private(set) var recentText: String = ""

    private init() {
        // Truncate if huge
        if let attrs = try? FileManager.default.attributesOfItem(atPath: Self.filePath),
           let size = attrs[.size] as? UInt64, size > 2_000_000 {
            try? FileManager.default.removeItem(atPath: Self.filePath)
        }
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
        lock.unlock()

        // File (append)
        if let data = (line + "\n").data(using: .utf8) {
            if !FileManager.default.fileExists(atPath: Self.filePath) {
                FileManager.default.createFile(atPath: Self.filePath, contents: data)
            } else if let h = try? FileHandle(forWritingTo: URL(fileURLWithPath: Self.filePath)) {
                defer { try? h.close() }
                h.seekToEndOfFile()
                h.write(data)
            }
        }
        #if DEBUG
        print(line)
        #else
        print(line)
        #endif

        DispatchQueue.main.async { [weak self] in
            self?.recentText = snapshot
        }
    }

    func section(_ title: String) {
        log("==== \(title) ====")
    }

    func clear() {
        lock.lock()
        lines.removeAll()
        lock.unlock()
        try? "".write(toFile: Self.filePath, atomically: true, encoding: .utf8)
        DispatchQueue.main.async { self.recentText = "" }
        log("log cleared")
    }

    func copyToPasteboard() {
        lock.lock()
        let all = lines.joined(separator: "\n")
        lock.unlock()
        // Also include full file if longer
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
