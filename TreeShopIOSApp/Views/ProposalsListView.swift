import SwiftUI
import CoreData

struct ProposalsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDProposal.createdAt, ascending: false)],
        animation: .default)
    private var proposals: FetchedResults<CDProposal>

    @State private var searchText = ""
    @State private var selectedStatus: String? = nil
    @State private var showingNewProposal = false

    let statusOptions = ["All", "Draft", "Sent", "Viewed", "Accepted", "Rejected", "Expired"]

    var filteredProposals: [CDProposal] {
        var filtered = Array(proposals)

        // Filter by status
        if let status = selectedStatus, status != "All" {
            filtered = filtered.filter { $0.status == status }
        }

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { proposal in
                (proposal.proposalNumber ?? "").localizedCaseInsensitiveContains(searchText) ||
                (proposal.customer?.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    var statistics: (sent: Int, accepted: Int, total: Double) {
        let sent = proposals.filter { $0.status == "Sent" || $0.status == "Viewed" }.count
        let accepted = proposals.filter { $0.status == "Accepted" }.count
        let total = proposals.filter { $0.status == "Accepted" }.reduce(0) { $0 + $1.total }
        return (sent, accepted, total)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Statistics Header
                StatisticsHeaderView(statistics: statistics)

                // Status Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(statusOptions, id: \.self) { status in
                            StatusFilterChip(
                                status: status,
                                isSelected: selectedStatus == status || (selectedStatus == nil && status == "All"),
                                count: countForStatus(status)
                            ) {
                                withAnimation {
                                    selectedStatus = status == "All" ? nil : status
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGray6))

                // Proposals List
                List {
                    if filteredProposals.isEmpty {
                        ContentUnavailableView(
                            "No Proposals",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("Create your first proposal to get started")
                        )
                    } else {
                        ForEach(filteredProposals) { proposal in
                            NavigationLink(destination: ProposalDetailView(proposal: proposal)) {
                                ProposalRowView(proposal: proposal)
                            }
                        }
                        .onDelete(perform: deleteProposals)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("TSO Proposals")
            .searchable(text: $searchText, prompt: "Search by number or customer...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewProposal = true }) {
                        Label("New Proposal", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewProposal) {
                ProposalBuilderV2View()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func countForStatus(_ status: String) -> Int {
        if status == "All" {
            return proposals.count
        } else {
            return proposals.filter { $0.status == status }.count
        }
    }

    private func deleteProposals(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredProposals[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("Error deleting proposal: \(error)")
            }
        }
    }
}

struct StatisticsHeaderView: View {
    let statistics: (sent: Int, accepted: Int, total: Double)

    var body: some View {
        HStack(spacing: 16) {
            StatisticCard(
                value: "\(statistics.sent)",
                label: "Pending",
                icon: "clock",
                color: .orange
            )

            StatisticCard(
                value: "\(statistics.accepted)",
                label: "Accepted",
                icon: "checkmark.circle",
                color: .green
            )

            StatisticCard(
                value: formatCurrency(statistics.total),
                label: "Revenue",
                icon: "dollarsign.circle",
                color: .blue
            )
        }
        .padding()
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct StatisticCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatusFilterChip: View {
    let status: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var statusColor: Color {
        switch status {
        case "Draft": return .gray
        case "Sent": return .blue
        case "Viewed": return .purple
        case "Accepted": return .green
        case "Rejected": return .red
        case "Expired": return .orange
        default: return .primary
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(status)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ? Color.white : statusColor.opacity(0.2)
                        )
                        .foregroundColor(isSelected ? statusColor : statusColor)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ? statusColor : Color(.systemBackground)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(statusColor.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProposalRowView: View {
    let proposal: CDProposal

    var statusColor: Color {
        switch proposal.status {
        case "Draft": return .gray
        case "Sent": return .blue
        case "Viewed": return .purple
        case "Accepted": return .green
        case "Rejected": return .red
        case "Expired": return .orange
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(proposal.proposalNumber ?? "No Number")
                        .font(.headline)

                    Text(proposal.customer?.name ?? "Unknown Customer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(proposal.total))
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)

                        Text(proposal.status ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                }
            }

            HStack {
                Label(proposal.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "",
                      systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if proposal.isExpired {
                    Label("Expired", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if proposal.daysUntilExpiration <= 2 {
                    Label("\(proposal.daysUntilExpiration) days left",
                          systemImage: "clock.badge.exclamationmark")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            if proposal.sortedLineItems.count > 0 {
                Text("\(proposal.sortedLineItems.count) line items")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct ProposalCardView: View {
    let proposal: CDProposal

    var statusColor: Color {
        switch proposal.status {
        case "Draft": return .gray
        case "Sent": return .blue
        case "Viewed": return .purple
        case "Accepted": return .green
        case "Rejected": return .red
        case "Expired": return .orange
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(proposal.proposalNumber ?? "")
                        .font(.headline)

                    Text(proposal.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(formatCurrency(proposal.total))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(proposal.status ?? "")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .foregroundColor(statusColor)
                .cornerRadius(8)

                if !proposal.isExpired && proposal.daysUntilExpiration <= 3 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(proposal.daysUntilExpiration) days")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                }

                Spacer()

                Text("\(proposal.sortedLineItems.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct ProposalDetailView: View {
    @ObservedObject var proposal: CDProposal
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                ProposalHeaderCard(proposal: proposal)

                // Customer Info
                if let customer = proposal.customer {
                    CustomerInfoCard(customer: customer)
                }

                // Line Items
                LineItemsCard(lineItems: proposal.sortedLineItems)

                // Pricing
                PricingCard(proposal: proposal)

                // Actions
                ActionsCard(
                    proposal: proposal,
                    onStatusChange: updateStatus,
                    onShare: { showShareSheet = true }
                )
            }
            .padding()
        }
        .navigationTitle("Proposal Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let proposalText = generateProposalText() {
                ShareSheet(items: [proposalText])
            }
        }
    }

    private func updateStatus(to newStatus: String) {
        proposal.status = newStatus
        proposal.updatedAt = Date()

        do {
            try viewContext.save()
        } catch {
            print("Error updating proposal status: \(error)")
        }
    }

    private func generateProposalText() -> String? {
        // Generate formatted proposal text for sharing
        var text = """
        TREESHOP PROFESSIONAL SERVICES
        Proposal: \(proposal.proposalNumber ?? "")
        Date: \(proposal.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "")

        CUSTOMER: \(proposal.customer?.name ?? "")
        """

        if let address = proposal.customer?.address {
            text += "\nADDRESS: \(address)"
        }

        text += "\n\nSERVICES:"
        for (index, item) in proposal.sortedLineItems.enumerated() {
            text += "\n\(index + 1). \(item.serviceType ?? "")"
            text += "\n   \(item.summary)"
            text += "\n   $\(String(format: "%.0f", item.totalPrice))"
        }

        text += "\n\nTOTAL: $\(String(format: "%.0f", proposal.total))"

        return text
    }
}

struct ProposalHeaderCard: View {
    let proposal: CDProposal

    var statusColor: Color {
        switch proposal.status {
        case "Draft": return .gray
        case "Sent": return .blue
        case "Viewed": return .purple
        case "Accepted": return .green
        case "Rejected": return .red
        case "Expired": return .orange
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(proposal.proposalNumber ?? "")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Created \(proposal.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(proposal.status ?? "")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)

                    if !proposal.isExpired {
                        Text("Expires in \(proposal.daysUntilExpiration) days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CustomerInfoCard: View {
    let customer: CDCustomer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Customer")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Label(customer.name ?? "", systemImage: "person")
                if let email = customer.email, !email.isEmpty {
                    Label(email, systemImage: "envelope")
                }
                if let phone = customer.phone, !phone.isEmpty {
                    Label(phone, systemImage: "phone")
                }
                if let address = customer.address, !address.isEmpty {
                    Label(address, systemImage: "location")
                }
            }
            .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct LineItemsCard: View {
    let lineItems: [CDLineItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services")
                .font(.headline)

            ForEach(Array(lineItems.enumerated()), id: \.element.id) { index, item in
                HStack {
                    Text("\(index + 1).")
                        .fontWeight(.medium)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.serviceType ?? "")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(item.summary)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("$\(String(format: "%.0f", item.totalPrice))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                if index < lineItems.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PricingCard: View {
    let proposal: CDProposal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pricing")
                .font(.headline)

            HStack {
                Text("Subtotal")
                    .foregroundColor(.secondary)
                Spacer()
                Text("$\(String(format: "%.0f", proposal.subtotal))")
            }
            .font(.subheadline)

            if proposal.discount > 0 {
                HStack {
                    Text("Discount")
                        .foregroundColor(.green)
                    Spacer()
                    Text("-$\(String(format: "%.0f", proposal.discount))")
                        .foregroundColor(.green)
                }
                .font(.subheadline)
            }

            Divider()

            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text("$\(String(format: "%.0f", proposal.total))")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ActionsCard: View {
    let proposal: CDProposal
    let onStatusChange: (String) -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if proposal.status == "Sent" || proposal.status == "Viewed" {
                HStack(spacing: 12) {
                    Button(action: { onStatusChange("Accepted") }) {
                        Label("Accept", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button(action: { onStatusChange("Rejected") }) {
                        Label("Reject", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }

            Button(action: onShare) {
                Label("Share Proposal", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    ProposalsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}