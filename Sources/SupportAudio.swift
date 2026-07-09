import AppKit

/// Bundled support audio (same `bravo.mp3` applause used in AMD Power Gadget).
enum SupportAudio {
    /// Keep a strong reference so playback is not deallocated mid-play.
    private static var player: NSSound?

    static func playApplause() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = Bundle.main.url(forResource: "bravo", withExtension: "mp3") else {
                rtlog("support audio: bravo.mp3 missing from bundle")
                return
            }
            guard let sound = NSSound(contentsOf: url, byReference: true) else {
                rtlog("support audio: could not load bravo.mp3")
                return
            }
            DispatchQueue.main.async {
                player?.stop()
                player = sound
                sound.play()
            }
        }
    }
}
