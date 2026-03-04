import ActivityKit
import Foundation
import SwiftUI

@MainActor
final class PinManager: ObservableObject {
    @Published private(set) var pinnedServiceNo: String?
    @Published private(set) var pinnedStopCode: String?

    private var currentActivity: Activity<BusLiveActivityAttributes>?
    private var updateTimer: Timer?

    private var busService: (any BusServiceProtocol)?
    private var stopCode: String?

    func isPinned(_ serviceNo: String) -> Bool {
        pinnedServiceNo == serviceNo
    }

    func pin(serviceNo: String, destination: String, stopName: String, stopCode: String, busService: any BusServiceProtocol, initialArrival: BusArrival?) {
        // Unpin existing first
        if pinnedServiceNo != nil {
            unpin()
        }

        self.busService = busService
        self.stopCode = stopCode
        pinnedServiceNo = serviceNo
        pinnedStopCode = stopCode

        let attributes = BusLiveActivityAttributes(
            serviceNo: serviceNo,
            destination: destination,
            stopName: stopName
        )

        let minutes = initialArrival?.nextBus.minutesAway
        let min2 = initialArrival?.nextBus2.minutesAway
        let min3 = initialArrival?.nextBus3.minutesAway
        let arrivalDate = initialArrival?.nextBus.estimatedArrival

        let state = BusLiveActivityAttributes.ContentState(
            nextBusMinutes: minutes,
            nextBus2Minutes: min2,
            nextBus3Minutes: min3,
            nextBusArrivalDate: arrivalDate
        )

        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(90))

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            startUpdateTimer()
        } catch {
            print("Failed to start Live Activity: \(error)")
            pinnedServiceNo = nil
            pinnedStopCode = nil
        }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func unpin() {
        updateTimer?.invalidate()
        updateTimer = nil

        if let activity = currentActivity {
            let finalState = BusLiveActivityAttributes.ContentState(
                nextBusMinutes: nil,
                nextBus2Minutes: nil,
                nextBus3Minutes: nil,
                nextBusArrivalDate: nil
            )
            Task {
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
        }

        currentActivity = nil
        pinnedServiceNo = nil
        pinnedStopCode = nil
        busService = nil
        stopCode = nil

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func cleanupOrphanedActivities() {
        Task {
            for activity in Activity<BusLiveActivityAttributes>.activities {
                let state = BusLiveActivityAttributes.ContentState(
                    nextBusMinutes: nil,
                    nextBus2Minutes: nil,
                    nextBus3Minutes: nil,
                    nextBusArrivalDate: nil
                )
                await activity.end(
                    ActivityContent(state: state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
        }
    }

    // MARK: - Timer

    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshActivity()
            }
        }
    }

    private func refreshActivity() async {
        guard let activity = currentActivity,
              let busService,
              let stopCode else { return }

        let arrivals = await busService.getArrivals(forStop: stopCode)
        guard let arrival = arrivals.first(where: { $0.serviceNo == pinnedServiceNo }) else { return }

        let minutes = arrival.nextBus.minutesAway
        let state = BusLiveActivityAttributes.ContentState(
            nextBusMinutes: minutes,
            nextBus2Minutes: arrival.nextBus2.minutesAway,
            nextBus3Minutes: arrival.nextBus3.minutesAway,
            nextBusArrivalDate: arrival.nextBus.estimatedArrival
        )

        let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(90))
        await activity.update(content)

        // Auto-end 30s after bus arrives
        if let min = minutes, min <= 0 {
            try? await Task.sleep(for: .seconds(30))
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: .default
            )
            self.currentActivity = nil
            self.pinnedServiceNo = nil
            self.pinnedStopCode = nil
            self.updateTimer?.invalidate()
            self.updateTimer = nil
        }
    }
}
