import Foundation
import CoreData

@objc(CDProposal)
public class CDProposal: NSManagedObject {

}

extension CDProposal {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDProposal> {
        return NSFetchRequest<CDProposal>(entityName: "Proposal")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var proposalNumber: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var expiresAt: Date?
    @NSManaged public var status: String?
    @NSManaged public var subtotal: Double
    @NSManaged public var discount: Double
    @NSManaged public var total: Double
    @NSManaged public var notes: String?
    @NSManaged public var includesCleanup: Bool
    @NSManaged public var includesHauling: Bool
    @NSManaged public var customer: CDCustomer?
    @NSManaged public var lineItems: NSSet?
}

// MARK: Generated accessors for lineItems
extension CDProposal {
    @objc(addLineItemsObject:)
    @NSManaged public func addToLineItems(_ value: CDLineItem)

    @objc(removeLineItemsObject:)
    @NSManaged public func removeFromLineItems(_ value: CDLineItem)

    @objc(addLineItems:)
    @NSManaged public func addToLineItems(_ values: NSSet)

    @objc(removeLineItems:)
    @NSManaged public func removeFromLineItems(_ values: NSSet)
}

extension CDProposal : Identifiable {
    public var sortedLineItems: [CDLineItem] {
        let items = lineItems as? Set<CDLineItem> ?? []
        return items.sorted { $0.sortOrder < $1.sortOrder }
    }

    public var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return expiresAt < Date()
    }

    public var daysUntilExpiration: Int {
        guard let expiresAt = expiresAt else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
        return max(0, days)
    }

    public var statusColor: String {
        switch status {
        case "Draft": return "gray"
        case "Sent": return "blue"
        case "Viewed": return "purple"
        case "Accepted": return "green"
        case "Rejected": return "red"
        case "Expired": return "orange"
        default: return "gray"
        }
    }
}