import SwiftUI

struct ArenaView: View {
    @Environment(AppStore.self) private var store
    @State private var category: ExerciseCategory = .strength
    @State private var search = ""
    @State private var selectedExercise: ExerciseDefinition?
    @State private var editingExercise: ExerciseDefinition?
    @State private var showingCustomEditor = false
    @State private var deletingExercise: ExerciseDefinition?
    @FocusState private var searchFocused: Bool

    private var filtered: [ExerciseDefinition] {
        store.allExercises.filter {
            $0.category == category &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Training Arena").font(.largeTitle.bold())
                    Label {
                        TextField("Search exercises...", text: $search)
                            .textInputAutocapitalization(.never)
                            .focused($searchFocused)
                    } icon: {
                        Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.secondary)
                    }
                    .padding(16)
                    .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(AppTheme.border))

                    SegmentedPill(values: ExerciseCategory.allCases, selection: $category, title: \.title)

                    Button {
                        editingExercise = nil
                        showingCustomEditor = true
                    } label: {
                        Label("Create Exercise", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(style: StrokeStyle(lineWidth: 1, dash: [5])))
                    }

                    if filtered.isEmpty {
                        EmptyStateView(symbol: "magnifyingglass", title: "No Exercises", message: search.isEmpty ? "Create an exercise for this category." : "Try a different search.")
                            .frame(minHeight: 250)
                    } else {
                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 16) {
                            ForEach(filtered) { exercise in
                                ExerciseCard(exercise: exercise) {
                                    selectedExercise = exercise
                                } edit: {
                                    editingExercise = exercise
                                    showingCustomEditor = true
                                } delete: {
                                    deletingExercise = exercise
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { searchFocused = false }
                }
            }
            .sheet(item: $selectedExercise) { WorkoutEditorView(exercise: $0) }
            .sheet(isPresented: $showingCustomEditor) {
                CustomExerciseEditorView(existing: editingExercise)
            }
            .confirmationDialog(
                "Delete \(deletingExercise?.name ?? "exercise")?",
                isPresented: Binding(get: { deletingExercise != nil }, set: { if !$0 { deletingExercise = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete Exercise", role: .destructive) {
                    if let deletingExercise { store.deleteCustomExercise(id: deletingExercise.id) }
                    deletingExercise = nil
                }
            } message: {
                Text("Existing workout history will remain.")
            }
        }
        .appScreen()
    }
}

private struct ExerciseCard: View {
    let exercise: ExerciseDefinition
    let start: () -> Void
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(exercise.emoji).font(.system(size: 44)).accessibilityHidden(true)
            Text(exercise.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(exercise.trackingKind.summary)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Button("Start Workout", action: start)
                .buttonStyle(.borderedProminent)
            if exercise.isCustom {
                HStack {
                    Button(action: edit) { Image(systemName: "pencil") }.accessibilityLabel("Edit \(exercise.name)")
                    Button(role: .destructive, action: delete) { Image(systemName: "trash") }.accessibilityLabel("Delete \(exercise.name)")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 210)
        .padding(14)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.border))
    }
}

struct WorkoutEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let exercise: ExerciseDefinition

    @State private var sets = ""
    @State private var reps = ""
    @State private var weight = ""
    @State private var distance = ""
    @State private var minutes = ""
    @State private var seconds = ""
    @State private var count = ""
    @State private var calories = ""
    @State private var notes = ""
    @State private var error: String?
    @FocusState private var focused: Field?

    private enum Field: Hashable { case sets, reps, weight, distance, minutes, seconds, count, calories, notes }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text(exercise.emoji).font(.system(size: 52))
                    trackingFields
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Notes")
                            Spacer()
                            Text("\(notes.count)/140").font(.caption).foregroundStyle(AppTheme.secondary)
                        }
                        TextEditor(text: $notes)
                            .focused($focused, equals: .notes)
                            .frame(minHeight: 110)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .background(AppTheme.field, in: RoundedRectangle(cornerRadius: 16))
                            .onChange(of: notes) { _, value in
                                if value.count > 140 { notes = String(value.prefix(140)) }
                            }
                    }
                    if let error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.yellow)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button("Finish Workout", action: save)
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } }
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focused = nil } }
            }
        }
        .appScreen()
    }

    @ViewBuilder
    private var trackingFields: some View {
        switch exercise.trackingKind {
        case .strengthWeight:
            integerField("Sets", text: $sets, field: .sets)
            integerField("Reps per set", text: $reps, field: .reps)
            decimalField("Weight", unit: store.profile?.unitSystem.weightUnit ?? "kg", text: $weight, field: .weight)
        case .strengthReps:
            integerField("Sets", text: $sets, field: .sets)
            integerField("Reps per set", text: $reps, field: .reps)
        case .cardioDistanceTime:
            decimalField("Distance", unit: store.profile?.unitSystem.distanceUnit ?? "km", text: $distance, field: .distance)
            durationFields
        case .cardioTimeCount:
            durationFields
            integerField("Count (optional)", text: $count, field: .count, required: false)
        case .cardioTimeCalories:
            durationFields
            integerField("Calories (optional)", text: $calories, field: .calories, required: false)
        case .staticDuration:
            durationFields
        case .staticDurationSets:
            integerField("Sets", text: $sets, field: .sets)
            durationFields
        }
    }

    private var durationFields: some View {
        HStack(spacing: 12) {
            integerField("Minutes", text: $minutes, field: .minutes, required: false)
            integerField("Seconds", text: $seconds, field: .seconds, required: false)
        }
    }

    private func integerField(_ title: String, text: Binding<String>, field: Field, required: Bool = true) -> some View {
        inputField(title, unit: nil, text: text, field: field, keyboard: .numberPad, required: required)
    }

    private func decimalField(_ title: String, unit: String, text: Binding<String>, field: Field) -> some View {
        inputField(title, unit: unit, text: text, field: field, keyboard: .decimalPad, required: true)
    }

    private func inputField(_ title: String, unit: String?, text: Binding<String>, field: Field, keyboard: UIKeyboardType, required: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(required ? title : "\(title)")
                .foregroundStyle(AppTheme.secondary)
            HStack {
                TextField(required ? "Required" : "Optional", text: text)
                    .keyboardType(keyboard)
                    .focused($focused, equals: field)
                    .accessibilityLabel(title)
                if let unit { Text(unit).foregroundStyle(AppTheme.secondary) }
            }
            .padding(16)
            .background(AppTheme.field, in: RoundedRectangle(cornerRadius: 16))
        }
        .frame(maxWidth: .infinity)
    }

    private func save() {
        let duration = (Int(minutes) ?? 0) * 60 + (Int(seconds) ?? 0)
        var record = WorkoutRecord(
            exerciseID: exercise.id,
            exerciseName: exercise.name,
            category: exercise.category,
            trackingKind: exercise.trackingKind,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        switch exercise.trackingKind {
        case .strengthWeight:
            guard let setValue = positiveInt(sets), let repValue = positiveInt(reps), let weightValue = positiveDouble(weight) else {
                return fail("Enter positive sets, reps and weight.")
            }
            record.sets = setValue
            record.reps = repValue
            record.weightKG = store.profile?.unitSystem == .imperial ? weightValue / 2.204_622_6218 : weightValue
        case .strengthReps:
            guard let setValue = positiveInt(sets), let repValue = positiveInt(reps) else {
                return fail("Enter positive sets and reps.")
            }
            record.sets = setValue
            record.reps = repValue
        case .cardioDistanceTime:
            guard let distanceValue = positiveDouble(distance), duration > 0 else {
                return fail("Enter a positive distance and duration.")
            }
            record.distanceKM = store.profile?.unitSystem == .imperial ? distanceValue * 1.609_344 : distanceValue
            record.durationSeconds = duration
        case .cardioTimeCount:
            guard duration > 0 || positiveInt(count) != nil else {
                return fail("Enter a duration or count.")
            }
            record.durationSeconds = duration > 0 ? duration : nil
            record.count = positiveInt(count)
        case .cardioTimeCalories:
            guard duration > 0 else { return fail("Enter a positive duration.") }
            record.durationSeconds = duration
            record.calories = positiveInt(calories)
        case .staticDuration:
            guard duration > 0 else { return fail("Enter a positive duration.") }
            record.durationSeconds = duration
        case .staticDurationSets:
            guard let setValue = positiveInt(sets), duration > 0 else {
                return fail("Enter positive sets and duration.")
            }
            record.sets = setValue
            record.durationSeconds = duration
        }

        store.addWorkout(record)
        dismiss()
    }

    private func fail(_ message: String) { error = message }
    private func positiveInt(_ text: String) -> Int? {
        guard let value = Int(text), value > 0, value < 100_000 else { return nil }
        return value
    }
    private func positiveDouble(_ text: String) -> Double? {
        guard let value = Double(text.replacingOccurrences(of: ",", with: ".")), value > 0, value < 100_000 else { return nil }
        return value
    }
}

struct CustomExerciseEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let existing: ExerciseDefinition?

    @State private var name = ""
    @State private var emoji = "✨"
    @State private var category: ExerciseCategory = .strength
    @State private var trackingKind: TrackingKind = .strengthWeight
    @State private var notes = ""
    @State private var error: String?
    @FocusState private var fieldFocused: Bool

    private var availableKinds: [TrackingKind] {
        switch category {
        case .strength: [.strengthWeight, .strengthReps]
        case .cardio: [.cardioDistanceTime, .cardioTimeCount, .cardioTimeCalories, .strengthReps]
        case .staticHold: [.staticDuration, .staticDurationSets]
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Exercise name", text: $name)
                        .focused($fieldFocused)
                    TextField("Emoji", text: $emoji)
                        .focused($fieldFocused)
                        .onChange(of: emoji) { _, value in
                            if value.count > 4 { emoji = String(value.prefix(4)) }
                        }
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(ExerciseCategory.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Tracking Type") {
                    ForEach(availableKinds, id: \.self) { kind in
                        Button {
                            trackingKind = kind
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(kind.summary).foregroundStyle(.white)
                                    Text(kind.rawValue).font(.caption).foregroundStyle(AppTheme.secondary)
                                }
                                Spacer()
                                if trackingKind == kind { Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.blue) }
                            }
                        }
                    }
                }
                Section("Notes (Optional)") {
                    TextField("How should this exercise be performed?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($fieldFocused)
                }
                if let error { Text(error).foregroundStyle(.yellow) }
                Section {
                    Button(existing == nil ? "Create Exercise" : "Save Exercise", action: save)
                        .buttonStyle(PrimaryButtonStyle())
                        .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(existing == nil ? "Create Custom Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { fieldFocused = false }
                }
            }
            .onAppear {
                guard let existing else { return }
                name = existing.name
                emoji = existing.emoji
                category = existing.category
                trackingKind = existing.trackingKind
                notes = existing.notes
            }
            .onChange(of: category) { _, _ in
                if !availableKinds.contains(trackingKind) { trackingKind = availableKinds[0] }
            }
        }
        .appScreen()
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanName.count >= 2 else {
            error = "Enter an exercise name with at least 2 characters."
            return
        }
        let duplicate = store.allExercises.contains {
            $0.id != existing?.id && $0.name.caseInsensitiveCompare(cleanName) == .orderedSame
        }
        guard !duplicate else {
            error = "An exercise with this name already exists."
            return
        }
        let exercise = ExerciseDefinition(
            id: existing?.id ?? "custom_\(UUID().uuidString)",
            name: cleanName,
            emoji: emoji.isEmpty ? "✨" : emoji,
            category: category,
            trackingKind: trackingKind,
            isCustom: true,
            notes: notes
        )
        if existing == nil { store.addCustomExercise(exercise) } else { store.updateCustomExercise(exercise) }
        dismiss()
    }
}
