import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ProposalsListView()
                .tabItem {
                    Label("Proposals", systemImage: "doc.text")
                }

            CustomersView()
                .tabItem {
                    Label("Customers", systemImage: "person.2")
                }

            ContentView()
                .tabItem {
                    Label("Catalog", systemImage: "tree")
                }

            DashboardView()
                .tabItem {
                    Label("Ops", systemImage: "chart.bar")
                }
        }
    }
}

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var stats = (totalProposals: 0, totalValue: 0.0, avgValue: 0.0, conversionRate: 0.0)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Key Metrics
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            MetricCard(
                                title: "Total Proposals",
                                value: "\(stats.totalProposals)",
                                icon: "doc.text",
                                color: .blue
                            )

                            MetricCard(
                                title: "Conversion Rate",
                                value: "\(Int(stats.conversionRate * 100))%",
                                icon: "chart.line.uptrend.xyaxis",
                                color: .green
                            )
                        }

                        HStack(spacing: 16) {
                            MetricCard(
                                title: "Total Revenue",
                                value: formatCurrency(stats.totalValue),
                                icon: "dollarsign.circle",
                                color: .purple
                            )

                            MetricCard(
                                title: "Avg Proposal",
                                value: formatCurrency(stats.avgValue),
                                icon: "chart.bar",
                                color: .orange
                            )
                        }
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            NavigationLink(destination: ProposalBuilderV2View()) {
                                QuickActionRow(
                                    title: "New Proposal",
                                    subtitle: "Create a new customer proposal",
                                    icon: "doc.badge.plus",
                                    color: .blue
                                )
                            }

                            NavigationLink(destination: AddCustomerView()) {
                                QuickActionRow(
                                    title: "Add Customer",
                                    subtitle: "Register a new customer",
                                    icon: "person.badge.plus",
                                    color: .green
                                )
                            }

                            NavigationLink(destination: ContentView()) {
                                QuickActionRow(
                                    title: "Service Catalog",
                                    subtitle: "Browse available services",
                                    icon: "list.bullet.rectangle",
                                    color: .orange
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Activity")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 8) {
                            ActivityRow(icon: "doc.badge.plus", text: "2 proposals created", time: "2 hours ago")
                            ActivityRow(icon: "checkmark.circle", text: "1 proposal accepted", time: "4 hours ago")
                            ActivityRow(icon: "person.badge.plus", text: "3 new customers", time: "5 hours ago")
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("TSO Dashboard")
            .onAppear {
                let coreDataManager = CoreDataManager()
                stats = coreDataManager.getStatistics()
            }
        }
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QuickActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ActivityRow: View {
    let icon: String
    let text: String
    let time: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)

            Spacer()

            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}