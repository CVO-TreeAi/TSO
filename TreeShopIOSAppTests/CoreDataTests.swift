import XCTest
import CoreData
@testable import TreeShopIOSApp

class CoreDataTests: XCTestCase {

    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        // Use in-memory store for testing
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }

    override func tearDown() {
        persistenceController = nil
        viewContext = nil
        super.tearDown()
    }

    // MARK: - Customer Tests

    func testCreateCustomer() {
        let customer = CDCustomer(context: viewContext)
        customer.id = UUID()
        customer.name = "John Doe"
        customer.email = "john@example.com"
        customer.phone = "555-1234"
        customer.address = "123 Main St"
        customer.createdAt = Date()

        XCTAssertNoThrow(try viewContext.save())

        let fetchRequest: NSFetchRequest<CDCustomer> = CDCustomer.fetchRequest()
        let customers = try? viewContext.fetch(fetchRequest)

        XCTAssertNotNil(customers)
        XCTAssertEqual(customers?.count, 1)
        XCTAssertEqual(customers?.first?.name, "John Doe")
    }

    func testUpdateCustomer() {
        // Create
        let customer = CDCustomer(context: viewContext)
        customer.id = UUID()
        customer.name = "Jane Smith"
        customer.email = "jane@example.com"

        try? viewContext.save()

        // Update
        customer.name = "Jane Doe"
        customer.phone = "555-9876"

        XCTAssertNoThrow(try viewContext.save())

        // Verify
        let fetchRequest: NSFetchRequest<CDCustomer> = CDCustomer.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", "jane@example.com")
        let customers = try? viewContext.fetch(fetchRequest)

        XCTAssertEqual(customers?.first?.name, "Jane Doe")
        XCTAssertEqual(customers?.first?.phone, "555-9876")
    }

    func testDeleteCustomer() {
        let customer = CDCustomer(context: viewContext)
        customer.id = UUID()
        customer.name = "To Delete"

        try? viewContext.save()

        viewContext.delete(customer)

        XCTAssertNoThrow(try viewContext.save())

        let fetchRequest: NSFetchRequest<CDCustomer> = CDCustomer.fetchRequest()
        let customers = try? viewContext.fetch(fetchRequest)

        XCTAssertEqual(customers?.count, 0)
    }

    // MARK: - Proposal Tests

    func testCreateProposal() {
        let customer = CDCustomer(context: viewContext)
        customer.id = UUID()
        customer.name = "Test Customer"

        let proposal = CDProposal(context: viewContext)
        proposal.id = UUID()
        proposal.proposalNumber = "TSO-2024-001"
        proposal.customer = customer
        proposal.totalAmount = 2500.00
        proposal.status = "Pending"
        proposal.createdAt = Date()

        XCTAssertNoThrow(try viewContext.save())

        let fetchRequest: NSFetchRequest<CDProposal> = CDProposal.fetchRequest()
        let proposals = try? viewContext.fetch(fetchRequest)

        XCTAssertEqual(proposals?.count, 1)
        XCTAssertEqual(proposals?.first?.proposalNumber, "TSO-2024-001")
        XCTAssertEqual(proposals?.first?.totalAmount, 2500.00)
    }

    func testProposalCustomerRelationship() {
        let customer = CDCustomer(context: viewContext)
        customer.id = UUID()
        customer.name = "Relationship Test"

        let proposal1 = CDProposal(context: viewContext)
        proposal1.id = UUID()
        proposal1.proposalNumber = "TSO-2024-002"
        proposal1.customer = customer

        let proposal2 = CDProposal(context: viewContext)
        proposal2.id = UUID()
        proposal2.proposalNumber = "TSO-2024-003"
        proposal2.customer = customer

        try? viewContext.save()

        // Verify relationship
        XCTAssertEqual(customer.proposals?.count, 2)
        XCTAssertNotNil(proposal1.customer)
        XCTAssertEqual(proposal1.customer?.name, "Relationship Test")
    }

    // MARK: - Line Item Tests

    func testCreateLineItem() {
        let proposal = CDProposal(context: viewContext)
        proposal.id = UUID()
        proposal.proposalNumber = "TSO-2024-004"

        let lineItem = CDLineItem(context: viewContext)
        lineItem.id = UUID()
        lineItem.itemDescription = "Tree Removal - Large Oak"
        lineItem.quantity = 1
        lineItem.unitPrice = 1500.00
        lineItem.totalPrice = 1500.00
        lineItem.proposal = proposal

        XCTAssertNoThrow(try viewContext.save())

        let fetchRequest: NSFetchRequest<CDLineItem> = CDLineItem.fetchRequest()
        let lineItems = try? viewContext.fetch(fetchRequest)

        XCTAssertEqual(lineItems?.count, 1)
        XCTAssertEqual(lineItems?.first?.itemDescription, "Tree Removal - Large Oak")
        XCTAssertEqual(lineItems?.first?.totalPrice, 1500.00)
    }

    func testMultipleLineItems() {
        let proposal = CDProposal(context: viewContext)
        proposal.id = UUID()
        proposal.proposalNumber = "TSO-2024-005"

        let items = [
            ("Tree Removal", 1, 1000.00),
            ("Stump Grinding", 1, 300.00),
            ("Cleanup", 1, 200.00)
        ]

        var total = 0.0
        for (desc, qty, price) in items {
            let lineItem = CDLineItem(context: viewContext)
            lineItem.id = UUID()
            lineItem.itemDescription = desc
            lineItem.quantity = Int16(qty)
            lineItem.unitPrice = price
            lineItem.totalPrice = Double(qty) * price
            lineItem.proposal = proposal
            total += lineItem.totalPrice
        }

        proposal.totalAmount = total

        try? viewContext.save()

        XCTAssertEqual(proposal.lineItems?.count, 3)
        XCTAssertEqual(proposal.totalAmount, 1500.00)
    }

    // MARK: - Work Order Tests

    func testCreateWorkOrder() {
        let customer = CDCustomer(context: viewContext)
        customer.id = UUID()
        customer.name = "Work Order Customer"

        let workOrder = CDWorkOrder(context: viewContext)
        workOrder.id = UUID()
        workOrder.workOrderNumber = "WO-2024-001"
        workOrder.customer = customer
        workOrder.scheduledDate = Date()
        workOrder.status = "Scheduled"
        workOrder.estimatedDuration = 4.0

        XCTAssertNoThrow(try viewContext.save())

        let fetchRequest: NSFetchRequest<CDWorkOrder> = CDWorkOrder.fetchRequest()
        let workOrders = try? viewContext.fetch(fetchRequest)

        XCTAssertEqual(workOrders?.count, 1)
        XCTAssertEqual(workOrders?.first?.workOrderNumber, "WO-2024-001")
        XCTAssertEqual(workOrders?.first?.estimatedDuration, 4.0)
    }

    func testWorkOrderStatusUpdates() {
        let workOrder = CDWorkOrder(context: viewContext)
        workOrder.id = UUID()
        workOrder.workOrderNumber = "WO-2024-002"
        workOrder.status = "Scheduled"

        try? viewContext.save()

        // Update status
        workOrder.status = "In Progress"
        workOrder.startedAt = Date()

        try? viewContext.save()

        // Complete
        workOrder.status = "Completed"
        workOrder.completedAt = Date()

        try? viewContext.save()

        let fetchRequest: NSFetchRequest<CDWorkOrder> = CDWorkOrder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "workOrderNumber == %@", "WO-2024-002")
        let orders = try? viewContext.fetch(fetchRequest)

        XCTAssertEqual(orders?.first?.status, "Completed")
        XCTAssertNotNil(orders?.first?.startedAt)
        XCTAssertNotNil(orders?.first?.completedAt)
    }

    // MARK: - Data Integrity Tests

    func testCascadeDelete() {
        let customer = CDCustomer(context: viewContext)
        customer.id = UUID()
        customer.name = "Cascade Test"

        let proposal = CDProposal(context: viewContext)
        proposal.id = UUID()
        proposal.customer = customer

        let lineItem = CDLineItem(context: viewContext)
        lineItem.id = UUID()
        lineItem.proposal = proposal

        try? viewContext.save()

        // Delete proposal should cascade to line items
        viewContext.delete(proposal)
        try? viewContext.save()

        let itemFetch: NSFetchRequest<CDLineItem> = CDLineItem.fetchRequest()
        let items = try? viewContext.fetch(itemFetch)

        XCTAssertEqual(items?.count, 0, "Line items should be deleted with proposal")
    }

    func testUniqueConstraints() {
        let customer1 = CDCustomer(context: viewContext)
        customer1.id = UUID()
        customer1.email = "unique@example.com"

        try? viewContext.save()

        let customer2 = CDCustomer(context: viewContext)
        customer2.id = UUID()
        customer2.email = "unique@example.com"

        // This should fail if unique constraint is properly set
        do {
            try viewContext.save()
            // If save succeeds, check if we have constraint setup
            let fetchRequest: NSFetchRequest<CDCustomer> = CDCustomer.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "email == %@", "unique@example.com")
            let customers = try? viewContext.fetch(fetchRequest)
            XCTAssertLessThanOrEqual(customers?.count ?? 0, 1, "Should enforce unique emails")
        } catch {
            // Expected behavior - constraint violation
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Performance Tests

    func testBulkInsertPerformance() {
        measure {
            for i in 1...100 {
                let customer = CDCustomer(context: viewContext)
                customer.id = UUID()
                customer.name = "Customer \(i)"
                customer.email = "customer\(i)@example.com"
            }

            try? viewContext.save()
        }
    }

    func testFetchPerformance() {
        // Setup data
        for i in 1...100 {
            let customer = CDCustomer(context: viewContext)
            customer.id = UUID()
            customer.name = "Customer \(i)"
        }
        try? viewContext.save()

        // Measure fetch
        measure {
            let fetchRequest: NSFetchRequest<CDCustomer> = CDCustomer.fetchRequest()
            _ = try? viewContext.fetch(fetchRequest)
        }
    }

    // MARK: - Query Tests

    func testComplexQuery() {
        // Create test data
        for i in 1...10 {
            let customer = CDCustomer(context: viewContext)
            customer.id = UUID()
            customer.name = "Customer \(i)"

            let proposal = CDProposal(context: viewContext)
            proposal.id = UUID()
            proposal.customer = customer
            proposal.totalAmount = Double(i * 1000)
            proposal.status = i % 2 == 0 ? "Accepted" : "Pending"
        }
        try? viewContext.save()

        // Complex query
        let fetchRequest: NSFetchRequest<CDProposal> = CDProposal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@ AND totalAmount > %f", "Accepted", 3000.0)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "totalAmount", ascending: false)]

        let results = try? viewContext.fetch(fetchRequest)

        XCTAssertNotNil(results)
        XCTAssertEqual(results?.count, 3) // 4000, 6000, 8000, 10000 but only those > 3000
        XCTAssertEqual(results?.first?.totalAmount, 10000.0)
    }
}

// Extension to support in-memory testing
extension PersistenceController {
    convenience init(inMemory: Bool) {
        self.init()
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
    }
}