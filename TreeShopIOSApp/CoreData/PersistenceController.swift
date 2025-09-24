import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TreeShopDataModel")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data Error: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Save Context

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - Preview Support

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample data for previews
        let sampleCustomer = CDCustomer(context: viewContext)
        sampleCustomer.id = UUID()
        sampleCustomer.name = "John Smith"
        sampleCustomer.email = "john@example.com"
        sampleCustomer.phone = "555-0123"
        sampleCustomer.address = "123 Main St, Springfield"
        sampleCustomer.createdAt = Date()
        sampleCustomer.updatedAt = Date()

        let sampleProposal = CDProposal(context: viewContext)
        sampleProposal.id = UUID()
        sampleProposal.proposalNumber = "EST-2024-001"
        sampleProposal.createdAt = Date()
        sampleProposal.updatedAt = Date()
        sampleProposal.expiresAt = Date().addingTimeInterval(7 * 24 * 60 * 60)
        sampleProposal.status = "Draft"
        sampleProposal.subtotal = 2500
        sampleProposal.discount = 250
        sampleProposal.total = 2250
        sampleProposal.customer = sampleCustomer

        do {
            try viewContext.save()
        } catch {
            print("Failed to create preview data: \(error)")
        }

        return result
    }()
}

// MARK: - Core Data Manager

class CoreDataManager: ObservableObject {
    let persistence = PersistenceController.shared

    // MARK: - Customer Operations

    func createCustomer(name: String, email: String, phone: String, address: String) -> CDCustomer {
        let context = persistence.container.viewContext
        let customer = CDCustomer(context: context)

        customer.id = UUID()
        customer.name = name
        customer.email = email
        customer.phone = phone
        customer.address = address
        customer.createdAt = Date()
        customer.updatedAt = Date()

        persistence.save()
        return customer
    }

    func fetchCustomers(searchText: String = "") -> [CDCustomer] {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDCustomer> = CDCustomer.fetchRequest()

        if !searchText.isEmpty {
            request.predicate = NSPredicate(
                format: "name CONTAINS[cd] %@ OR email CONTAINS[cd] %@ OR phone CONTAINS[cd] %@",
                searchText, searchText, searchText
            )
        }

        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching customers: \(error)")
            return []
        }
    }

    // MARK: - Proposal Operations

    func saveProposal(from proposal: ProposalV2, customer: CDCustomer? = nil) -> CDProposal {
        let context = persistence.container.viewContext

        // Create or find customer
        let cdCustomer: CDCustomer
        if let existingCustomer = customer {
            cdCustomer = existingCustomer
        } else {
            cdCustomer = createCustomer(
                name: proposal.customerName,
                email: proposal.customerEmail,
                phone: proposal.customerPhone,
                address: proposal.propertyAddress
            )
        }

        // Create proposal
        let cdProposal = CDProposal(context: context)
        cdProposal.id = UUID()
        cdProposal.proposalNumber = generateProposalNumber()
        cdProposal.createdAt = Date()
        cdProposal.updatedAt = Date()
        cdProposal.expiresAt = Date().addingTimeInterval(Double(proposal.validDays) * 24 * 60 * 60)
        cdProposal.status = "Sent"
        cdProposal.subtotal = proposal.subtotal
        cdProposal.discount = proposal.discountAmount
        cdProposal.total = proposal.total
        cdProposal.notes = proposal.notes
        cdProposal.includesCleanup = proposal.includesCleanup
        cdProposal.includesHauling = proposal.includesHauling
        cdProposal.customer = cdCustomer

        // Add line items
        for (index, lineItem) in proposal.lineItems.enumerated() {
            let cdLineItem = CDLineItem(context: context)
            cdLineItem.id = UUID()
            cdLineItem.serviceType = lineItem.type.rawValue
            cdLineItem.quantity = lineItem.quantity
            cdLineItem.unitPrice = lineItem.type.baseRate
            cdLineItem.totalPrice = lineItem.calculatedPrice
            cdLineItem.itemDescription = lineItem.description
            cdLineItem.sortOrder = Int16(index)

            // Tree measurements
            cdLineItem.treeHeight = lineItem.height ?? 0
            cdLineItem.treeDBH = lineItem.dbh ?? 0
            cdLineItem.treeCanopy = (lineItem.canopyRadius ?? 0) * 2 // Store as diameter
            cdLineItem.trimPercent = lineItem.trimPercent ?? 0

            // Stump measurements
            cdLineItem.stumpDiameter = lineItem.stumpDiameter ?? 0
            cdLineItem.grindDepth = lineItem.grindDepth ?? 0

            // Land clearing
            cdLineItem.acres = lineItem.acres ?? 0
            cdLineItem.maxDBH = lineItem.maxDBH ?? 0

            // Complexity - calculate from accessDifficulty
            cdLineItem.complexityMultiplier = lineItem.accessDifficulty
            cdLineItem.nearStructure = lineItem.nearStructure
            cdLineItem.powerLines = lineItem.powerLines
            cdLineItem.slope = lineItem.slope

            cdLineItem.proposal = cdProposal
        }

        persistence.save()
        return cdProposal
    }

    func fetchProposals(status: String? = nil, searchText: String = "") -> [CDProposal] {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDProposal> = CDProposal.fetchRequest()

        var predicates: [NSPredicate] = []

        if let status = status {
            predicates.append(NSPredicate(format: "status == %@", status))
        }

        if !searchText.isEmpty {
            predicates.append(NSPredicate(
                format: "proposalNumber CONTAINS[cd] %@ OR customer.name CONTAINS[cd] %@",
                searchText, searchText
            ))
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching proposals: \(error)")
            return []
        }
    }

    func updateProposalStatus(proposal: CDProposal, status: String) {
        proposal.status = status
        proposal.updatedAt = Date()
        persistence.save()
    }

    private func generateProposalNumber() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: date)

        let context = persistence.container.viewContext
        let request: NSFetchRequest<CDProposal> = CDProposal.fetchRequest()
        request.predicate = NSPredicate(format: "proposalNumber BEGINSWITH %@", "EST-\(dateString)")

        let count = (try? context.count(for: request)) ?? 0
        return "EST-\(dateString)-\(String(format: "%03d", count + 1))"
    }

    // MARK: - Statistics

    func getStatistics() -> (totalProposals: Int, totalValue: Double, avgValue: Double, conversionRate: Double) {
        let proposals = fetchProposals()
        let totalProposals = proposals.count
        let totalValue = proposals.reduce(0) { $0 + ($1.total) }
        let avgValue = totalProposals > 0 ? totalValue / Double(totalProposals) : 0

        let acceptedCount = proposals.filter { $0.status == "Accepted" }.count
        let conversionRate = totalProposals > 0 ? Double(acceptedCount) / Double(totalProposals) : 0

        return (totalProposals, totalValue, avgValue, conversionRate)
    }
}