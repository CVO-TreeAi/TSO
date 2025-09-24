import SwiftUI

struct AFISSAssessmentView: View {
    @StateObject private var manager: AFISSManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State private var showingSceneDescriber = false
    @State private var showingPresets = false

    let onComplete: (AFISSAssessment) -> Void
    let baseScore: Double

    init(
        currentAssessment: AFISSAssessment = AFISSAssessment(),
        baseScore: Double,
        onComplete: @escaping (AFISSAssessment) -> Void
    ) {
        self.baseScore = baseScore
        self.onComplete = onComplete
        _manager = StateObject(wrappedValue: {
            let m = AFISSManager()
            m.assessment = currentAssessment
            m.initialize(baseScore: baseScore)
            return m
        }())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar

                // Quick Actions
                quickActions

                // Category Tabs or Search Results
                if manager.searchText.isEmpty {
                    categoryTabs
                } else {
                    searchResultsList
                }

                // Bottom Summary Bar
                bottomSummaryBar
            }
            .navigationTitle("Site Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onComplete(manager.assessment)
                        dismiss()
                    }
                    .bold()
                }
            }
            .sheet(isPresented: $showingSceneDescriber) {
                SceneDescriberView(manager: manager)
            }
            .sheet(isPresented: $showingPresets) {
                PresetsView(manager: manager)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search assessment factors...", text: $manager.searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .autocorrectionDisabled()

            if !manager.searchText.isEmpty {
                Button(action: {
                    manager.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button(action: { showingSceneDescriber = true }) {
                Label("Describe Scene", systemImage: "text.viewfinder")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button(action: { showingPresets = true }) {
                Label("Presets", systemImage: "list.bullet.rectangle")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if !manager.assessment.selectedFactors.isEmpty {
                Button(action: { manager.clearAll() }) {
                    Label("Clear", systemImage: "xmark.circle")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        VStack(spacing: 0) {
            // Category Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(AFISSCategory.allCases, id: \.self) { category in
                        CategoryTab(
                            category: category,
                            isSelected: manager.selectedCategory == category,
                            factorCount: manager.assessment.factors(for: category).count
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                manager.selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            Divider()

            // Factor List
            if let category = manager.selectedCategory {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(AFISSDatabase.factors(for: category)) { factor in
                            FactorRow(
                                factor: factor,
                                isSelected: manager.isSelected(factor),
                                afScore: manager.getAFScore(for: factor)
                            ) {
                                withAnimation(.spring(response: 0.2)) {
                                    manager.toggleFactor(factor)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                // Category Selection Prompt
                VStack(spacing: 20) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Select a category to view factors")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if manager.searchResults.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No factors found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try different search terms")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(manager.searchResults) { factor in
                        FactorRow(
                            factor: factor,
                            isSelected: manager.isSelected(factor),
                            afScore: manager.getAFScore(for: factor),
                            showCategory: true
                        ) {
                            withAnimation(.spring(response: 0.2)) {
                                manager.toggleFactor(factor)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Bottom Summary Bar

    private var bottomSummaryBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Factors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(manager.assessment.selectedFactors.count) factors")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total AF Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(manager.getTotalAFScore())")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Category Tab Component

struct CategoryTab: View {
    let category: AFISSCategory
    let isSelected: Bool
    let factorCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : category.color)

                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                if factorCount > 0 {
                    Text("\(factorCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : category.color)
                        .cornerRadius(8)
                }
            }
            .frame(width: 70, height: 70)
            .background(isSelected ? category.color : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Factor Row Component

struct FactorRow: View {
    let factor: AssessmentFactor
    let isSelected: Bool
    let afScore: Int
    var showCategory: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .green : .secondary)

                // Factor Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(factor.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        if showCategory {
                            Text(factor.category.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(factor.category.color.opacity(0.15))
                                .foregroundColor(factor.category.color)
                                .cornerRadius(4)
                        }
                    }

                    Text(factor.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // AF Score
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Text("+\(afScore)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(isSelected ? .green : .secondary)
                    }
                    Text("points")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.green.opacity(0.08) : Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scene Describer View

struct SceneDescriberView: View {
    @ObservedObject var manager: AFISSManager
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Describe the work site and I'll suggest relevant assessment factors")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextEditor(text: $manager.sceneDescription)
                    .focused($isFocused)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .frame(minHeight: 150)
                    .padding(.horizontal)

                if !manager.suggestedFactors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested Factors")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(manager.suggestedFactors) { factor in
                                    HStack {
                                        Image(systemName: factor.category.icon)
                                            .foregroundColor(factor.category.color)
                                        Text(factor.name)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("+\(manager.getAFScore(for: factor))")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Button("Apply Suggestions") {
                        manager.applySuggestions()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(manager.suggestedFactors.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Describe Scene")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Presets View

struct PresetsView: View {
    @ObservedObject var manager: AFISSManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(AFISSPreset.presets, id: \.name) { preset in
                Button(action: {
                    manager.applyPreset(preset)
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(preset.name)
                            .font(.headline)
                        Text(preset.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(preset.factorNames.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Quick Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AFISSAssessmentView(
        baseScore: 100,
        onComplete: { assessment in
            print("Total AF Score: \(assessment.totalAFScore)")
        }
    )
}