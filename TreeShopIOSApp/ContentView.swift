import SwiftUI

struct ContentView: View {
    @StateObject private var lineItemsData = LineItemsData()
    @State private var selectedCategory: ServiceCategory? = nil
    @State private var searchText = ""
    @State private var selectedItem: LineItem? = nil
    @State private var showingProposalGenerator = false

    var filteredItems: [LineItem] {
        let categoryFiltered = selectedCategory != nil
            ? lineItemsData.items.filter { $0.category == selectedCategory }
            : lineItemsData.items

        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List {
                CategoryFilterSection(selectedCategory: $selectedCategory)

                Section("Services (\(filteredItems.count))") {
                    ForEach(filteredItems) { item in
                        NavigationLink(destination: LineItemDetailView(item: item)) {
                            LineItemRowView(item: item)
                        }
                    }
                }
            }
            .navigationTitle("Ops Service Catalog")
            .searchable(text: $searchText, prompt: "Search services...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingProposalGenerator = true }) {
                        Label("New Proposal", systemImage: "doc.badge.plus")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedCategory != nil {
                        Button("Clear Filter") {
                            withAnimation {
                                selectedCategory = nil
                            }
                        }
                    }
                }
            }
        } detail: {
            if let item = selectedItem {
                LineItemDetailView(item: item)
            } else {
                EmptyStateView()
            }
        }
        .sheet(isPresented: $showingProposalGenerator) {
            ProposalBuilderV2View()
        }
    }
}

struct CategoryFilterSection: View {
    @Binding var selectedCategory: ServiceCategory?

    var body: some View {
        Section("Categories") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ServiceCategory.allCases) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: {
                                withAnimation(.spring()) {
                                    if selectedCategory == category {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = category
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
}

struct CategoryChip: View {
    let category: ServiceCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color : category.color.opacity(0.15))
            )
            .foregroundColor(isSelected ? .white : category.color)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LineItemRowView: View {
    let item: LineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.category.icon)
                    .foregroundColor(item.category.color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(item.name)
                        .font(.headline)
                        .lineLimit(2)
                }

                Spacer()
            }

            Text(item.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)

            HStack {
                Label(item.unitOfMeasurement, systemImage: "ruler")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if let packages = item.packages {
                    Text("\(packages.count) packages")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tree.fill")
                .font(.system(size: 80))
                .foregroundColor(.green.opacity(0.3))

            Text("Select a Service")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Choose a tree service from the list to view details")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    ContentView()
}