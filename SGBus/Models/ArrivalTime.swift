import Foundation

struct ArrivalTime: Identifiable {
    let id = UUID()
    let estimatedArrival: Date?

    var minutesAway: Int? {
        guard let estimatedArrival else { return nil }
        let interval = estimatedArrival.timeIntervalSince(Date.now)
        return max(0, Int(interval / 60))
    }

    var displayText: String {
        guard let minutes = minutesAway else { return "-" }
        if minutes <= 0 { return "Arr" }
        return "\(minutes)"
    }

    var isArriving: Bool {
        guard let minutes = minutesAway else { return false }
        return minutes <= 1
    }

    var isSoon: Bool {
        guard let minutes = minutesAway else { return false }
        return minutes > 1 && minutes <= 4
    }
}
