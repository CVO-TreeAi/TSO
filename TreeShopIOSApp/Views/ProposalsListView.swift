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
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
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
            HStack(spacing: 6) {
                Text(status)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected ? Color.white : statusColor.opacity(0.2)
                    )
                    .foregroundColor(
                        isSelected ? statusColor : .primary
                    )
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? statusColor : Color.clear
            )
            .foregroundColor(
                isSelected ? .white : .primary
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(statusColor, lineWidth: isSelected ? 0 : 1)
            )
            .cornerRadius(20)
        }
    }
}

struct ProposalRowView: View {
    @ObservedObject var proposal: CDProposal

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
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Proposal #\(proposal.proposalNumber ?? "")")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(proposal.customer?.name ?? "Unknown Customer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(proposal.status ?? "Draft")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(6)

                    Text(proposal.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Service Summary
            if let lineItems = proposal.lineItems as? Set<CDLineItem>, !lineItems.isEmpty {
                Text(servicesSummary(for: lineItems))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // Footer
            HStack {
                Label("\(proposal.lineItems?.count ?? 0) items", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("$\(String(format: "%.0f", proposal.total))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 4)
    }

    private func servicesSummary(for lineItems: Set<CDLineItem>) -> String {
        let services = lineItems.compactMap { $0.serviceType }
        let uniqueServices = Set(services)
        let serviceList = uniqueServices.prefix(2).joined(separator: ", ")
        return uniqueServices.count > 2 ? "\(serviceList), +\(uniqueServices.count - 2) more" : serviceList
    }
}

#Preview {
    ProposalsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}