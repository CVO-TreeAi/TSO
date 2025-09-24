import Foundation
import CoreData

@objc(CDWorkOrder)
public class CDWorkOrder: NSManagedObject {

}

extension CDWorkOrder {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDWorkOrder> {
        return NSFetchRequest<CDWorkOrder>(entityName: "WorkOrder")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var workOrderNumber: String?
    @NSManaged public var scheduledDate: Date?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var estimatedDuration: Double
    @NSManaged public var actualDuration: Double
    @NSManaged public var status: String?
    @NSManaged public var priority: Int16
    @NSManaged public var crewAssigned: String?
    @NSManaged public var equipmentRequired: String?
    @NSManaged public var safetyNotes: String?
    @NSManaged public var completionNotes: String?
    @NSManaged public var weatherConditions: String?
    @NSManaged public var calendarEventId: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var proposal: CDProposal?
    @NSManaged public var customer: CDCustomer?
}

extension CDWorkOrder : Identifiable {
    public var displayStatus: String {
        status ?? "Scheduled"
    }

    public var priorityLevel: String {
        switch priority {
        case 1: return "Emergency"
        case 2: return "High"
        case 3: return "Normal"
        case 4: return "Low"
        default: return "Normal"
        }
    }

    public var isOverdue: Bool {
        guard let scheduled = scheduledDate else { return false }
        return scheduled < Date() && status != "Completed"
    }

    public var formattedDuration: String {
        let hours = Int(estimatedDuration)
        let minutes = Int((estimatedDuration - Double(hours)) * 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}