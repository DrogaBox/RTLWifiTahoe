import Foundation

// MARK: - Duration → TimeInterval conversion

extension Duration {
    /// Convenience conversion to Foundation `TimeInterval` (seconds as Double).
    /// Useful when working with APIs that take `TimeInterval` (e.g. `Date.addingTimeInterval`).
    var timeInterval: TimeInterval {
        let (sec, atto) = self.components
        return TimeInterval(sec) + TimeInterval(atto) / 1_000_000_000_000_000_000
    }
}
