import EventKit
import SwiftUI
import CoreData

class EventKitManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false

    init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = authorizationStatus == .fullAccess || authorizationStatus == .writeOnly
    }

    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    self.isAuthorized = granted
                    self.checkAuthorizationStatus()
                }
                return granted
            } catch {
                print("Error requesting calendar access: \(error)")
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    Task { @MainActor in
                        self.isAuthorized = granted
                        self.checkAuthorizationStatus()
                    }
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func createCalendarEvent(for workOrder: CDWorkOrder) async throws -> String? {
        if !isAuthorized {
            let granted = await requestAccess()
            if !granted {
                throw EventKitError.notAuthorized
            }
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "Work Order: \(workOrder.customer?.name ?? "Unknown Customer")"

        if let scheduledDate = workOrder.scheduledDate {
            event.startDate = scheduledDate
            event.endDate = scheduledDate.addingTimeInterval(workOrder.estimatedDuration * 3600)
        }

        event.location = workOrder.customer?.address

        var notes = "Work Order #\(workOrder.workOrderNumber ?? "N/A")\n"
        notes += "Customer: \(workOrder.customer?.name ?? "Unknown")\n"
        notes += "Priority: \(workOrder.priorityLevel)\n"

        if let crewAssigned = workOrder.crewAssigned {
            notes += "Crew: \(crewAssigned)\n"
        }

        if let equipmentRequired = workOrder.equipmentRequired {
            notes += "Equipment: \(equipmentRequired)\n"
        }

        if let safetyNotes = workOrder.safetyNotes {
            notes += "\nSafety Notes:\n\(safetyNotes)"
        }

        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents

        // Add alerts
        let alert1 = EKAlarm(relativeOffset: -3600) // 1 hour before
        let alert2 = EKAlarm(relativeOffset: -86400) // 1 day before
        event.alarms = [alert1, alert2]

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw EventKitError.failedToSaveEvent(error)
        }
    }

    func updateCalendarEvent(for workOrder: CDWorkOrder) async throws {
        guard let eventId = workOrder.calendarEventId,
              isAuthorized else { return }

        guard let event = eventStore.event(withIdentifier: eventId) else {
            // Event doesn't exist, create a new one
            let newEventId = try await createCalendarEvent(for: workOrder)
            workOrder.calendarEventId = newEventId
            return
        }

        // Update the existing event
        event.title = "Work Order: \(workOrder.customer?.name ?? "Unknown Customer")"

        if let scheduledDate = workOrder.scheduledDate {
            event.startDate = scheduledDate
            event.endDate = scheduledDate.addingTimeInterval(workOrder.estimatedDuration * 3600)
        }

        event.location = workOrder.customer?.address

        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw EventKitError.failedToUpdateEvent(error)
        }
    }

    func deleteCalendarEvent(for workOrder: CDWorkOrder) async throws {
        guard let eventId = workOrder.calendarEventId,
              isAuthorized,
              let event = eventStore.event(withIdentifier: eventId) else { return }

        do {
            try eventStore.remove(event, span: .thisEvent)
            workOrder.calendarEventId = nil
        } catch {
            throw EventKitError.failedToDeleteEvent(error)
        }
    }

    func getUpcomingWorkOrders() async throws -> [EKEvent] {
        guard isAuthorized else {
            throw EventKitError.notAuthorized
        }

        let calendars = eventStore.calendars(for: .event)
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)!

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)

        return events.filter { $0.title?.contains("Work Order:") == true }
    }
}

enum EventKitError: LocalizedError {
    case notAuthorized
    case failedToSaveEvent(Error)
    case failedToUpdateEvent(Error)
    case failedToDeleteEvent(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized"
        case .failedToSaveEvent(let error):
            return "Failed to save event: \(error.localizedDescription)"
        case .failedToUpdateEvent(let error):
            return "Failed to update event: \(error.localizedDescription)"
        case .failedToDeleteEvent(let error):
            return "Failed to delete event: \(error.localizedDescription)"
        }
    }
}