import Foundation
import CoreData

class CoreDataSyncManager {
    static let shared = CoreDataSyncManager()
    private let context = PersistenceController.shared.container.viewContext

    private init() {}

    func getLocalChanges() throws -> LocalChanges {
        let customers = try fetchModifiedCustomers()
        let proposals = try fetchModifiedProposals()
        let workOrders = try fetchModifiedWorkOrders()

        return LocalChanges(
            customers: customers,
            proposals: proposals,
            workOrders: workOrders,
            timestamp: Date()
        )
    }

    func applyRemoteChanges(_ syncResult: SyncResult) throws {
        if let remoteCustomers = syncResult.remoteChanges?.customers {
            try mergeCustomers(remoteCustomers)
        }

        if let remoteProposals = syncResult.remoteChanges?.proposals {
            try mergeProposals(remoteProposals)
        }

        if let remoteWorkOrders = syncResult.remoteChanges?.workOrders {
            try mergeWorkOrders(remoteWorkOrders)
        }

        try context.save()
    }

    private func fetchModifiedCustomers() throws -> [APICustomer] {
        let request: NSFetchRequest<CDCustomer> = CDCustomer.fetchRequest()
        let lastSync = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date ?? Date.distantPast
        request.predicate = NSPredicate(format: "updatedAt > %@", lastSync as NSDate)

        let cdCustomers = try context.fetch(request)
        return cdCustomers.map { cdCustomer in
            APICustomer(
                id: cdCustomer.id ?? UUID(),
                name: cdCustomer.name ?? "",
                email: cdCustomer.email,
                phone: cdCustomer.phone,
                address: cdCustomer.address,
                createdAt: cdCustomer.createdAt ?? Date(),
                updatedAt: cdCustomer.updatedAt ?? Date()
            )
        }
    }

    private func fetchModifiedProposals() throws -> [APIProposal] {
        let request: NSFetchRequest<CDProposal> = CDProposal.fetchRequest()
        let lastSync = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date ?? Date.distantPast
        request.predicate = NSPredicate(format: "updatedAt > %@", lastSync as NSDate)

        let cdProposals = try context.fetch(request)
        return cdProposals.map { cdProposal in
            APIProposal(
                id: cdProposal.id ?? UUID(),
                proposalNumber: cdProposal.proposalNumber ?? "",
                customerId: cdProposal.customer?.id ?? UUID(),
                totalAmount: cdProposal.total,
                status: cdProposal.status ?? "pending",
                lineItems: nil,
                createdAt: cdProposal.createdAt ?? Date(),
                updatedAt: cdProposal.updatedAt ?? Date()
            )
        }
    }

    private func fetchModifiedWorkOrders() throws -> [WorkOrder] {
        let request: NSFetchRequest<CDWorkOrder> = CDWorkOrder.fetchRequest()
        let lastSync = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date ?? Date.distantPast
        request.predicate = NSPredicate(format: "updatedAt > %@", lastSync as NSDate)

        let cdWorkOrders = try context.fetch(request)
        return cdWorkOrders.map { cdWorkOrder in
            WorkOrder(
                id: cdWorkOrder.id ?? UUID(),
                workOrderNumber: cdWorkOrder.workOrderNumber ?? "",
                customerId: cdWorkOrder.customer?.id ?? UUID(),
                scheduledDate: cdWorkOrder.scheduledDate ?? Date(),
                status: cdWorkOrder.status ?? "scheduled",
                estimatedDuration: cdWorkOrder.estimatedDuration
            )
        }
    }

    private func mergeCustomers(_ remoteCustomers: [APICustomer]) throws {
        for remoteCustomer in remoteCustomers {
            let request: NSFetchRequest<CDCustomer> = CDCustomer.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", remoteCustomer.id as CVarArg)

            if let existingCustomer = try context.fetch(request).first {
                // Update existing
                existingCustomer.name = remoteCustomer.name
                existingCustomer.email = remoteCustomer.email
                existingCustomer.phone = remoteCustomer.phone
                existingCustomer.address = remoteCustomer.address
                existingCustomer.updatedAt = remoteCustomer.updatedAt
            } else {
                // Create new
                let newCustomer = CDCustomer(context: context)
                newCustomer.id = remoteCustomer.id
                newCustomer.name = remoteCustomer.name
                newCustomer.email = remoteCustomer.email
                newCustomer.phone = remoteCustomer.phone
                newCustomer.address = remoteCustomer.address
                newCustomer.createdAt = remoteCustomer.createdAt
                newCustomer.updatedAt = remoteCustomer.updatedAt
            }
        }
    }

    private func mergeProposals(_ remoteProposals: [APIProposal]) throws {
        // Similar implementation for proposals
    }

    private func mergeWorkOrders(_ remoteWorkOrders: [WorkOrder]) throws {
        // Similar implementation for work orders
    }
}

struct LocalChanges: Codable {
    let customers: [APICustomer]?
    let proposals: [APIProposal]?
    let workOrders: [WorkOrder]?
    let timestamp: Date
}