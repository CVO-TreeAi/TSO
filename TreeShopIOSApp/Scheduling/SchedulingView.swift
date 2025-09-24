import SwiftUI
import CoreData
import EventKit

struct SchedulingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var eventKitManager = EventKitManager()

    @FetchRequest(
        entity: CDWorkOrder.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CDWorkOrder.scheduledDate, ascending: true),
            NSSortDescriptor(keyPath: \CDWorkOrder.priority, ascending: true)
        ],
        predicate: NSPredicate(format: "status != %@", "Completed")
    )
    private var workOrders: FetchedResults<CDWorkOrder>

    @State private var selectedDate = Date()
    @State private var showingNewWorkOrder = false
    @State private var selectedWorkOrder: CDWorkOrder?
    @State private var viewMode: ViewMode = .list

    enum ViewMode {
        case list, calendar, map
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode picker
                Picker("View Mode", selection: $viewMode) {
                    Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                    Label("Calendar", systemImage: "calendar").tag(ViewMode.calendar)
                    Label("Map", systemImage: "map").tag(ViewMode.map)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                switch viewMode {
                case .list:
                    WorkOrderListView(workOrders: Array(workOrders), selectedWorkOrder: $selectedWorkOrder)

                case .calendar:
                    CalendarScheduleView(workOrders: Array(workOrders), selectedDate: $selectedDate)

                case .map:
                    WorkOrderMapView(workOrders: Array(workOrders))
                }
            }
            .navigationTitle("Schedule & Dispatch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewWorkOrder = true }) {
                        Label("New Work Order", systemImage: "plus")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: syncWithCalendar) {
                        Label("Sync Calendar", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingNewWorkOrder) {
                CreateWorkOrderView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $selectedWorkOrder) { workOrder in
                WorkOrderDetailView(workOrder: workOrder)
                    .environment(\.managedObjectContext, viewContext)
            }
            .onAppear {
                checkCalendarAuthorization()
            }
        }
    }

    func checkCalendarAuthorization() {
        Task {
            if !eventKitManager.isAuthorized {
                _ = await eventKitManager.requestAccess()
            }
        }
    }

    func syncWithCalendar() {
        Task {
            for workOrder in workOrders {
                if workOrder.calendarEventId == nil {
                    do {
                        let eventId = try await eventKitManager.createCalendarEvent(for: workOrder)
                        workOrder.calendarEventId = eventId
                    } catch {
                        print("Failed to create calendar event: \(error)")
                    }
                } else {
                    do {
                        try await eventKitManager.updateCalendarEvent(for: workOrder)
                    } catch {
                        print("Failed to update calendar event: \(error)")
                    }
                }
            }

            do {
                try viewContext.save()
            } catch {
                print("Failed to save calendar sync: \(error)")
            }
        }
    }
}

struct WorkOrderListView: View {
    let workOrders: [CDWorkOrder]
    @Binding var selectedWorkOrder: CDWorkOrder?

    var groupedWorkOrders: [(String, [CDWorkOrder])] {
        let grouped = Dictionary(grouping: workOrders) { workOrder in
            if let date = workOrder.scheduledDate {
                if Calendar.current.isDateInToday(date) {
                    return "Today"
                } else if Calendar.current.isDateInTomorrow(date) {
                    return "Tomorrow"
                } else {
                    return date.formatted(date: .abbreviated, time: .omitted)
                }
            }
            return "Unscheduled"
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        List {
            ForEach(groupedWorkOrders, id: \.0) { section in
                Section(header: Text(section.0)) {
                    ForEach(section.1) { workOrder in
                        WorkOrderRowView(workOrder: workOrder)
                            .onTapGesture {
                                selectedWorkOrder = workOrder
                            }
                    }
                }
            }
        }
    }
}

struct WorkOrderRowView: View {
    @ObservedObject var workOrder: CDWorkOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(workOrder.customer?.name ?? "Unknown Customer")
                        .font(.headline)

                    if let address = workOrder.customer?.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(workOrder.priorityLevel)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)

                    if let scheduledDate = workOrder.scheduledDate {
                        Text(scheduledDate, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack {
                if let crew = workOrder.crewAssigned {
                    Label(crew, systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(workOrder.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    var priorityColor: Color {
        switch workOrder.priority {
        case 1: return .red
        case 2: return .orange
        case 3: return .blue
        default: return .gray
        }
    }
}

struct CalendarScheduleView: View {
    let workOrders: [CDWorkOrder]
    @Binding var selectedDate: Date

    var body: some View {
        VStack {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()

            List {
                ForEach(workOrdersForSelectedDate) { workOrder in
                    WorkOrderRowView(workOrder: workOrder)
                }
            }
        }
    }

    var workOrdersForSelectedDate: [CDWorkOrder] {
        workOrders.filter { workOrder in
            guard let scheduledDate = workOrder.scheduledDate else { return false }
            return Calendar.current.isDate(scheduledDate, inSameDayAs: selectedDate)
        }
    }
}

struct WorkOrderMapView: View {
    let workOrders: [CDWorkOrder]

    var body: some View {
        Text("Map view showing work order locations")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
    }
}

struct CreateWorkOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var eventKitManager = EventKitManager()

    @State private var selectedCustomer: CDCustomer?
    @State private var selectedProposal: CDProposal?
    @State private var scheduledDate = Date()
    @State private var estimatedDuration: Double = 2.0
    @State private var priority: Int16 = 3
    @State private var crewAssigned = ""
    @State private var equipmentRequired = ""
    @State private var safetyNotes = ""
    @State private var addToCalendar = true

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDCustomer.name, ascending: true)]
    )
    private var customers: FetchedResults<CDCustomer>

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer & Proposal") {
                    Picker("Customer", selection: $selectedCustomer) {
                        Text("Select Customer").tag(nil as CDCustomer?)
                        ForEach(customers) { customer in
                            Text(customer.name ?? "Unknown").tag(customer as CDCustomer?)
                        }
                    }

                    if let customer = selectedCustomer {
                        Picker("Proposal", selection: $selectedProposal) {
                            Text("No Proposal").tag(nil as CDProposal?)
                            ForEach(Array(customer.proposals as? Set<CDProposal> ?? [])) { proposal in
                                Text("Proposal #\(proposal.proposalNumber ?? "")").tag(proposal as CDProposal?)
                            }
                        }
                    }
                }

                Section("Schedule") {
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
            .navigationTitle("New Work Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWorkOrder()
                    }
                    .bold()
                    .disabled(selectedCustomer == nil)
                }
            }
        }
    }

    func saveWorkOrder() {
        let newWorkOrder = CDWorkOrder(context: viewContext)
        newWorkOrder.id = UUID()
        newWorkOrder.workOrderNumber = generateWorkOrderNumber()
        newWorkOrder.customer = selectedCustomer
        newWorkOrder.proposal = selectedProposal
        newWorkOrder.scheduledDate = scheduledDate
        newWorkOrder.estimatedDuration = estimatedDuration
        newWorkOrder.priority = priority
        newWorkOrder.crewAssigned = crewAssigned.isEmpty ? nil : crewAssigned
        newWorkOrder.equipmentRequired = equipmentRequired.isEmpty ? nil : equipmentRequired
        newWorkOrder.safetyNotes = safetyNotes.isEmpty ? nil : safetyNotes
        newWorkOrder.status = "Scheduled"
        newWorkOrder.createdAt = Date()
        newWorkOrder.updatedAt = Date()

        do {
            try viewContext.save()

            if addToCalendar {
                Task {
                    do {
                        let eventId = try await eventKitManager.createCalendarEvent(for: newWorkOrder)
                        newWorkOrder.calendarEventId = eventId
                        try viewContext.save()
                    } catch {
                        print("Failed to create calendar event: \(error)")
                    }
                }
            }

            dismiss()
        } catch {
            print("Error saving work order: \(error)")
        }
    }

    func generateWorkOrderNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: Date())
        let random = Int.random(in: 1000...9999)
        return "WO-\(dateString)-\(random)"
    }
}

struct WorkOrderDetailView: View {
    @ObservedObject var workOrder: CDWorkOrder
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer Information") {
                    LabeledContent("Customer", value: workOrder.customer?.name ?? "Unknown")
                    if let address = workOrder.customer?.address {
                        LabeledContent("Address", value: address)
                    }
                    if let phone = workOrder.customer?.phone {
                        LabeledContent("Phone", value: phone)
                    }
                }

                Section("Schedule") {
                    if let scheduledDate = workOrder.scheduledDate {
                        LabeledContent("Date", value: scheduledDate.formatted(date: .complete, time: .omitted))
                        LabeledContent("Time", value: scheduledDate.formatted(date: .omitted, time: .shortened))
                    }
                    LabeledContent("Duration", value: workOrder.formattedDuration)
                    LabeledContent("Priority", value: workOrder.priorityLevel)
                    LabeledContent("Status", value: workOrder.displayStatus)
                }

                if let crew = workOrder.crewAssigned {
                    Section("Assignment") {
                        LabeledContent("Crew", value: crew)
                        if let equipment = workOrder.equipmentRequired {
                            LabeledContent("Equipment", value: equipment)
                        }
                    }
                }

                if let safetyNotes = workOrder.safetyNotes {
                    Section("Safety Notes") {
                        Text(safetyNotes)
                    }
                }
            }
            .navigationTitle("Work Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SchedulingView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}