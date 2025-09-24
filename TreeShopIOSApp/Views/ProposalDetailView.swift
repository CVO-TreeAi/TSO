import SwiftUI
import CoreData

struct ProposalDetailView: View {
    @ObservedObject var proposal: CDProposal
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingConvertToWorkOrder = false
    @State private var showingStatusUpdate = false
    @State private var showingEditProposal = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status Card
                ProposalStatusCard(proposal: proposal)

                // Customer Information
                if let customer = proposal.customer {
                    CustomerInfoCard(customer: customer)
                }

                // Proposal Details
                ProposalDetailsCard(proposal: proposal)

                // Line Items
                LineItemsSection(proposal: proposal)

                // Total Summary
                TotalSummaryCard(proposal: proposal)

                // Action Buttons
                ActionButtonsSection(
                    proposal: proposal,
                    onAccept: { convertToWorkOrder() },
                    onReject: { rejectProposal() },
                    onEdit: { showingEditProposal = true }
                )
            }
            .padding()
        }
        .navigationTitle("Proposal #\(proposal.proposalNumber ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditProposal = true
                    } label: {
                        Label("Edit Proposal", systemImage: "pencil")
                    }

                    Button {
                        showingStatusUpdate = true
                    } label: {
                        Label("Update Status", systemImage: "arrow.triangle.2.circlepath")
                    }

                    if proposal.status == "Accepted" {
                        Button {
                            convertToWorkOrder()
                        } label: {
                            Label("Convert to Work Order", systemImage: "doc.badge.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingConvertToWorkOrder) {
            ConvertToWorkOrderView(proposal: proposal)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingEditProposal) {
            // Edit proposal view (to be implemented)
            Text("Edit Proposal View")
        }
    }

    func convertToWorkOrder() {
        proposal.status = "Accepted"
        showingConvertToWorkOrder = true
    }

    func rejectProposal() {
        proposal.status = "Rejected"
        proposal.updatedAt = Date()
        do {
            try viewContext.save()
        } catch {
            print("Error rejecting proposal: \(error)")
        }
    }
}

struct ProposalStatusCard: View {
    @ObservedObject var proposal: CDProposal

    var statusColor: Color {
        switch proposal.status {
        case "Accepted": return .green
        case "Rejected": return .red
        case "Sent", "Viewed": return .orange
        case "Expired": return .gray
        default: return .blue
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(proposal.status ?? "Draft")
                    .font(.headline)
                    .foregroundColor(statusColor)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Created")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(proposal.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CustomerInfoCard: View {
    let customer: CDCustomer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Customer")
                .font(.headline)

            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text(customer.name ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let email = customer.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let phone = customer.phone {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            if let address = customer.address {
                Label(address, systemImage: "location")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct ProposalDetailsCard: View {
    let proposal: CDProposal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Proposal Number:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(proposal.proposalNumber ?? "N/A")
                        .font(.subheadline)
                }

                HStack {
                    Text("Valid Until:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(proposal.expiresAt?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")
                        .font(.subheadline)
                }

                HStack {
                    Text("Includes Cleanup:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: proposal.includesCleanup ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(proposal.includesCleanup ? .green : .red)
                }

                HStack {
                    Text("Includes Hauling:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: proposal.includesHauling ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(proposal.includesHauling ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct LineItemsSection: View {
    let proposal: CDProposal

    var lineItems: [CDLineItem] {
        let items = proposal.lineItems as? Set<CDLineItem> ?? []
        return items.sorted { ($0.sortOrder) < ($1.sortOrder) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services")
                .font(.headline)

            ForEach(lineItems) { item in
                ProposalLineItemRow(item: item)
            }
        }
    }
}

struct ProposalLineItemRow: View {
    let item: CDLineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.serviceType ?? "Service")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(formatCurrency(item.totalPrice))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            if let description = item.itemDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Qty: \(Int(item.quantity))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("@ \(formatCurrency(item.unitPrice))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct TotalSummaryCard: View {
    let proposal: CDProposal

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Subtotal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatCurrency(proposal.subtotal))
                    .font(.subheadline)
            }

            if proposal.discount > 0 {
                HStack {
                    Text("Discount")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("-\(formatCurrency(proposal.discount))")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }

            Divider()

            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text(formatCurrency(proposal.total))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct ActionButtonsSection: View {
    let proposal: CDProposal
    let onAccept: () -> Void
    let onReject: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if proposal.status == "Draft" || proposal.status == "Sent" {
                Button(action: onAccept) {
                    Label("Accept & Convert to Work Order", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                HStack(spacing: 12) {
                    Button(action: onReject) {
                        Label("Reject", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            } else if proposal.status == "Accepted" {
                Text("✓ Proposal Accepted")
                    .font(.headline)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
            } else if proposal.status == "Rejected" {
                Text("✗ Proposal Rejected")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
            }
        }
    }
}

struct ConvertToWorkOrderView: View {
    let proposal: CDProposal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var eventKitManager = EventKitManager()

    @State private var scheduledDate = Date()
    @State private var estimatedDuration: Double = 4.0
    @State private var priority: Int16 = 3
    @State private var crewAssigned = ""
    @State private var equipmentRequired = ""
    @State private var safetyNotes = ""
    @State private var addToCalendar = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Proposal Information") {
                    LabeledContent("Customer", value: proposal.customer?.name ?? "Unknown")
                    LabeledContent("Proposal #", value: proposal.proposalNumber ?? "")
                    LabeledContent("Total Value", value: formatCurrency(proposal.total))
                }

                Section("Schedule Work Order") {
                    DatePicker("Scheduled Date", selection: $scheduledDate)

                    HStack {
                        Text("Estimated Duration")
                        Spacer()
                        Text("\(Int(estimatedDuration)) hours")
                    }
                    Slider(value: $estimatedDuration, in: 0.5...12, step: 0.5)

                    Picker("Priority", selection: $priority) {
                        Text("Emergency").tag(Int16(1))
                        Text("High").tag(Int16(2))
                        Text("Normal").tag(Int16(3))
                        Text("Low").tag(Int16(4))
                    }
                }

                Section("Assignment") {
                    TextField("Crew Assigned", text: $crewAssigned)
                    TextField("Equipment Required", text: $equipmentRequired)
                    TextField("Safety Notes", text: $safetyNotes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("Add to Calendar", isOn: $addToCalendar)
                }
            }
            .navigationTitle("Convert to Work Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createWorkOrder()
                    }
                    .bold()
                }
            }
        }
    }

    func createWorkOrder() {
        let workOrder = CDWorkOrder(context: viewContext)
        workOrder.id = UUID()
        workOrder.workOrderNumber = generateWorkOrderNumber()
        workOrder.customer = proposal.customer
        workOrder.proposal = proposal
        workOrder.scheduledDate = scheduledDate
        workOrder.estimatedDuration = estimatedDuration
        workOrder.priority = priority
        workOrder.crewAssigned = crewAssigned.isEmpty ? nil : crewAssigned
        workOrder.equipmentRequired = equipmentRequired.isEmpty ? nil : equipmentRequired
        workOrder.safetyNotes = safetyNotes.isEmpty ? nil : safetyNotes
        workOrder.status = "Scheduled"
        workOrder.createdAt = Date()
        workOrder.updatedAt = Date()

        // Update proposal status
        proposal.status = "Accepted"
        proposal.updatedAt = Date()

        do {
            try viewContext.save()

            if addToCalendar {
                Task {
                    do {
                        let eventId = try await eventKitManager.createCalendarEvent(for: workOrder)
                        workOrder.calendarEventId = eventId
                        try viewContext.save()
                    } catch {
                        print("Failed to create calendar event: \(error)")
                    }
                }
            }

            dismiss()
        } catch {
            print("Error creating work order: \(error)")
        }
    }

    func generateWorkOrderNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: Date())
        let random = Int.random(in: 1000...9999)
        return "WO-\(dateString)-\(random)"
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

#Preview {
    // Preview disabled - requires Core Data context setup
    Text("Proposal Detail View")
}