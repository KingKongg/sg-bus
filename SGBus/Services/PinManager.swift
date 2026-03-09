import ActivityKit
import BackgroundTasks
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

    static let bgTaskIdentifier = "com.sgbus.refreshLiveActivity"

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

        let state = BusLiveActivityAttributes.ContentState(
            nextBusArrival: initialArrival?.nextBus.estimatedArrival,
            nextBus2Arrival: initialArrival?.nextBus2.estimatedArrival,
            nextBus3Arrival: initialArrival?.nextBus3.estimatedArrival
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
            print("[PinManager] Failed to start Live Activity: \(error)")
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
                nextBusArrival: nil,
                nextBus2Arrival: nil,
                nextBus3Arrival: nil
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
                    nextBusArrival: nil,
                    nextBus2Arrival: nil,
                    nextBus3Arrival: nil
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

    func refreshActivity() async {
        guard let activity = currentActivity,
              let busService,
              let stopCode else { return }

        do {
            let arrivals = try await busService.getArrivals(forStop: stopCode)
            guard let arrival = arrivals.first(where: { $0.serviceNo == pinnedServiceNo }) else {
                print("[PinManager] No arrival found for service \(pinnedServiceNo ?? "nil")")
                return
            }

            let state = BusLiveActivityAttributes.ContentState(
                nextBusArrival: arrival.nextBus.estimatedArrival,
                nextBus2Arrival: arrival.nextBus2.estimatedArrival,
                nextBus3Arrival: arrival.nextBus3.estimatedArrival
            )

            let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(90))
            await activity.update(content)

            // Auto-end when service stops operating (e.g., late at night)
            if !arrival.isOperating {
                try? await Task.sleep(for: .seconds(5))
                await activity.end(
                    ActivityContent(state: state, staleDate: nil),
                    dismissalPolicy: .default
                )
                self.currentActivity = nil
                self.pinnedServiceNo = nil
                self.pinnedStopCode = nil
                self.updateTimer?.invalidate()
                self.updateTimer = nil
                return
            }

            // Auto-end 30s after bus arrives
            if let minutes = arrival.nextBus.minutesAway, minutes <= 0 {
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
        } catch {
            print("[PinManager] Failed to refresh Live Activity: \(error)")
        }
    }

    // MARK: - Background Task

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.bgTaskIdentifier, using: nil) { [weak self] task in
            guard let task = task as? BGAppRefreshTask else { return }
            Task { @MainActor in
                await self?.handleBackgroundRefresh(task: task)
            }
        }
    }

    func scheduleBackgroundRefresh() {
        guard pinnedServiceNo != nil else { return }
        let request = BGAppRefreshTaskRequest(identifier: Self.bgTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[PinManager] Failed to schedule background refresh: \(error)")
        }
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) async {
        // Schedule the next refresh before doing work
        scheduleBackgroundRefresh()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        await refreshActivity()
        task.setTaskCompleted(success: true)
    }
}
