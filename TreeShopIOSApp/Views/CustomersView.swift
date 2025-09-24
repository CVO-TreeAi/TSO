import SwiftUI
import CoreData

struct CustomersView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDCustomer.name, ascending: true)],
        animation: .default)
    private var customers: FetchedResults<CDCustomer>

    @State private var searchText = ""
    @State private var showingAddCustomer = false
    @State private var selectedCustomer: CDCustomer?

    var filteredCustomers: [CDCustomer] {
        if searchText.isEmpty {
            return Array(customers)
        } else {
            return customers.filter { customer in
                (customer.name ?? "").localizedCaseInsensitiveContains(searchText) ||
                (customer.email ?? "").localizedCaseInsensitiveContains(searchText) ||
                (customer.phone ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredCustomers.isEmpty {
                    ContentUnavailableView("No Customers",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Tap + to add your first customer"))
                } else {
                    ForEach(filteredCustomers) { customer in
                        NavigationLink(destination: CustomerDetailView(customer: customer)) {
                            CustomerRowView(customer: customer)
                        }
                    }
                    .onDelete(perform: deleteCustomers)
                }
            }
            .navigationTitle("TSO Customers")
            .searchable(text: $searchText, prompt: "Search customers...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCustomer = true }) {
                        Label("Add Customer", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomer) {
                AddCustomerView()
            }
        }
    }

    private func deleteCustomers(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredCustomers[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("Error deleting customer: \(error)")
            }
        }
    }
}

struct CustomerRowView: View {
    let customer: CDCustomer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(customer.name ?? "Unknown")
                        .font(.headline)

                    if let email = customer.email, !email.isEmpty {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let phone = customer.phone, !phone.isEmpty {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(customer.proposalCount)")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Proposals")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if customer.totalValue > 0 {
                HStack {
                    Text("Total Value:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(customer.totalValue))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.leading, 44)
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

struct AddCustomerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("Address") {
                    TextField("Property Address", text: $address)
                        .textContentType(.fullStreetAddress)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCustomer()
                    }
                    .disabled(name.isEmpty)
                    .bold()
                }
            }
        }
    }

    private func saveCustomer() {
        let newCustomer = CDCustomer(context: viewContext)
        newCustomer.id = UUID()
        newCustomer.name = name
        newCustomer.email = email
        newCustomer.phone = phone
        newCustomer.address = address
        newCustomer.notes = notes
        newCustomer.createdAt = Date()
        newCustomer.updatedAt = Date()

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving customer: \(error)")
        }
    }
}

struct CustomerDetailView: View {
    @ObservedObject var customer: CDCustomer
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEditCustomer = false
    @State private var showingNewProposal = false

    var sortedProposals: [CDProposal] {
        let proposals = customer.proposals as? Set<CDProposal> ?? []
        return proposals.sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Customer Info Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading) {
                            Text(customer.name ?? "Unknown")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Customer since \(customer.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: { showingEditCustomer = true }) {
                            Label("Edit", systemImage: "pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }

                    Divider()

                    // Contact Info
                    VStack(alignment: .leading, spacing: 8) {
                        if let email = customer.email, !email.isEmpty {
                            Label(email, systemImage: "envelope")
                                .font(.subheadline)
                        }

                        if let phone = customer.phone, !phone.isEmpty {
                            Label(phone, systemImage: "phone")
                                .font(.subheadline)
                        }

                        if let address = customer.address, !address.isEmpty {
                            Label(address, systemImage: "location")
                                .font(.subheadline)
                        }
                    }

                    if let notes = customer.notes, !notes.isEmpty {
                        Divider()
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)

                // Statistics
                HStack(spacing: 16) {
                    StatCard(
                        title: "Proposals",
                        value: "\(customer.proposalCount)",
                        icon: "doc.text",
                        color: .blue
                    )

                    StatCard(
                        title: "Total Value",
                        value: formatCurrency(customer.totalValue),
                        icon: "dollarsign.circle",
                        color: .green
                    )

                    if customer.proposalCount > 0 {
                        StatCard(
                            title: "Avg Value",
                            value: formatCurrency(customer.totalValue / Double(customer.proposalCount)),
                            icon: "chart.bar",
                            color: .purple
                        )
                    }
                }

                // Proposals Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Proposals")
                            .font(.headline)

                        Spacer()

                        Button(action: { showingNewProposal = true }) {
                            Label("New Proposal", systemImage: "plus")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if sortedProposals.isEmpty {
                        Text("No proposals yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(sortedProposals) { proposal in
                            NavigationLink(destination: ProposalDetailView(proposal: proposal)) {
                                ProposalCardView(proposal: proposal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Customer Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditCustomer) {
            EditCustomerView(customer: customer)
        }
        .sheet(isPresented: $showingNewProposal) {
            ProposalBuilderV2View()
                .environment(\.managedObjectContext, viewContext)
        }
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EditCustomerView: View {
    @ObservedObject var customer: CDCustomer
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("Address") {
                    TextField("Property Address", text: $address)
                        .textContentType(.fullStreetAddress)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .bold()
                }
            }
            .onAppear {
                name = customer.name ?? ""
                email = customer.email ?? ""
                phone = customer.phone ?? ""
                address = customer.address ?? ""
                notes = customer.notes ?? ""
            }
        }
    }

    private func saveChanges() {
        customer.name = name
        customer.email = email
        customer.phone = phone
        customer.address = address
        customer.notes = notes
        customer.updatedAt = Date()

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error updating customer: \(error)")
        }
    }
}

#Preview {
    CustomersView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}