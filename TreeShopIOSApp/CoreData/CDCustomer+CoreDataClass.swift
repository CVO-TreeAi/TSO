import Foundation
import CoreData

@objc(CDCustomer)
public class CDCustomer: NSManagedObject {

}

extension CDCustomer {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCustomer> {
        return NSFetchRequest<CDCustomer>(entityName: "Customer")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var address: String?
    @NSManaged public var notes: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var proposals: NSSet?
}

// MARK: Generated accessors for proposals
extension CDCustomer {
    @objc(addProposalsObject:)
    @NSManaged public func addToProposals(_ value: CDProposal)

    @objc(removeProposalsObject:)
    @NSManaged public func removeFromProposals(_ value: CDProposal)

    @objc(addProposals:)
    @NSManaged public func addToProposals(_ values: NSSet)

    @objc(removeProposals:)
    @NSManaged public func removeFromProposals(_ values: NSSet)
}

extension CDCustomer : Identifiable {
    public var proposalCount: Int {
        proposals?.count ?? 0
    }

    public var totalValue: Double {
        guard let proposals = proposals as? Set<CDProposal> else { return 0 }
        return proposals.reduce(0) { $0 + ($1.total) }
    }

    public var lastProposalDate: Date? {
        guard let proposals = proposals as? Set<CDProposal> else { return nil }
        return proposals.map { $0.createdAt ?? Date.distantPast }.max()
    }
}