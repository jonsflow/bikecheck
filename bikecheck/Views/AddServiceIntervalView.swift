import SwiftUI

struct AddServiceIntervalView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: AddServiceIntervalViewModel

    @State private var showingResetSheet = false
    @State private var pendingResetNote = ""
    @State private var pendingResetDate = Date()

    @State private var showingNoteSheet = false
    @State private var pendingNoteText = ""
    @State private var pendingNoteDate = Date()

    init(serviceInterval: ServiceInterval? = nil) {
        _viewModel = StateObject(wrappedValue: AddServiceIntervalViewModel(serviceInterval: serviceInterval))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Service Details")) {
                    Picker("Bike", selection: $viewModel.selectedBike) {
                        ForEach(viewModel.bikes, id: \.self) { bike in
                            Text(bike.name).tag(bike as Bike?)
                        }
                    }
                    .accessibilityIdentifier("BikePicker")

                    Picker("Part", selection: $viewModel.selectedTemplate) {
                        Text("Custom...").tag(nil as PartTemplate?)

                        ForEach(PartTemplateService.shared.getAllCategories()) { category in
                            Section(header: Text(category.name)) {
                                ForEach(PartTemplateService.shared.getTemplatesByCategory(category.id)) { template in
                                    HStack {
                                        Image(systemName: template.icon)
                                        Text(template.name)
                                    }
                                    .tag(template as PartTemplate?)
                                }
                            }
                        }
                    }
                    .accessibilityIdentifier("PartTemplatePicker")
                    .onChange(of: viewModel.selectedTemplate) { _ in
                        viewModel.applyTemplate()
                    }

                    if viewModel.selectedTemplate == nil {
                        HStack {
                            Text("Custom Part Name:")
                            Spacer()
                            TextField("Part", text: $viewModel.part)
                                .multilineTextAlignment(.trailing)
                                .accessibilityIdentifier("PartTextField")
                        }
                    }

                    HStack {
                        Text("Interval Time (hrs)")
                        Spacer()
                        TextField("Interval Time (hrs)", text: $viewModel.intervalTime)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("IntervalTimeTextField")
                    }

                    if viewModel.serviceInterval != nil {
                        HStack {
                            Text("Time until service (hrs)")
                            Spacer()
                            Text(viewModel.timeUntilServiceText)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(
                                    (Double(viewModel.timeUntilServiceText) ?? 0) <= 0 ? .red : .primary
                                )
                        }
                    }

                    Toggle(isOn: $viewModel.notify) {
                        Text("Notify")
                    }
                    .accessibilityIdentifier("NotifyToggle")

                    DatePicker("Last Service Date", selection: $viewModel.lastServiceDate, displayedComponents: .date)
                        .accessibilityIdentifier("LastServiceDatePicker")
                        .onChange(of: viewModel.lastServiceDate) { _ in
                            viewModel.updateTimeUntilService()
                        }
                }

                if viewModel.serviceInterval != nil {
                    Section {
                        Button(action: {
                            pendingResetDate = Date()
                            pendingResetNote = ""
                            showingResetSheet = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset Interval")
                            }
                            .foregroundColor(.blue)
                        }
                        .accessibilityIdentifier("ResetIntervalButton")
                    }

                    Section(header: HStack {
                        Text("Service History")
                        Spacer()
                        Button {
                            pendingNoteDate = Date()
                            pendingNoteText = ""
                            showingNoteSheet = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add Note")
                            }
                            .font(.caption)
                        }
                    }) {
                        if viewModel.serviceRecords.isEmpty {
                            Text("No service history yet")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.serviceRecords) { record in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: record.isReset ? "wrench.and.screwdriver" : "note.text")
                                        .foregroundColor(record.isReset ? .blue : .secondary)
                                        .frame(width: 20)
                                        .padding(.top, 2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(record.date ?? Date(), format: .dateTime.month(.abbreviated).day().year())
                                            .font(.subheadline)
                                        if let note = record.note, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    Section {
                        Button(action: {
                            viewModel.deleteConfirmationDialog = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete")
                            }
                            .foregroundColor(.red)
                        }
                        .accessibilityIdentifier("DeleteIntervalButton")
                        .alert(isPresented: $viewModel.deleteConfirmationDialog) {
                            Alert(
                                title: Text("Confirm Removal"),
                                message: Text("Are you sure you want to remove this service interval?"),
                                primaryButton: .destructive(Text("Remove")) {
                                    viewModel.deleteInterval()
                                    presentationMode.wrappedValue.dismiss()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }

                Section {
                    AdContainerView()
                }
            }
            .navigationBarItems(
                leading: viewModel.serviceInterval == nil ? Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                } : nil,
                trailing: viewModel.serviceInterval == nil ? Button("Save") {
                    viewModel.saveServiceInterval()
                    presentationMode.wrappedValue.dismiss()
                } : nil
            )
            .onAppear {
                viewModel.loadBikes()
            }
            .sheet(isPresented: $showingNoteSheet) {
                NavigationView {
                    Form {
                        Section {
                            DatePicker(
                                "Date",
                                selection: $pendingNoteDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                        }
                        Section {
                            TextField("Note", text: $pendingNoteText, axis: .vertical)
                                .lineLimit(3...6)
                        }
                    }
                    .navigationTitle("Add Note")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingNoteSheet = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Add") {
                                viewModel.addNote(note: pendingNoteText, date: pendingNoteDate)
                                showingNoteSheet = false
                                pendingNoteText = ""
                                pendingNoteDate = Date()
                            }
                            .disabled(pendingNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingResetSheet) {
                NavigationView {
                    Form {
                        Section {
                            DatePicker(
                                "Service Date",
                                selection: $pendingResetDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                        }
                        Section {
                            TextField("Add a note (optional)", text: $pendingResetNote)
                        }
                    }
                    .navigationTitle("Log Service")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingResetSheet = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Log Service") {
                                viewModel.resetInterval(note: pendingResetNote, date: pendingResetDate)
                                showingResetSheet = false
                                pendingResetNote = ""
                                pendingResetDate = Date()
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            if viewModel.serviceInterval != nil && viewModel.hasUnsavedChanges {
                viewModel.saveServiceInterval()
            }
        }
    }
}
