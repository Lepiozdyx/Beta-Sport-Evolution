import SwiftUI

struct DashboardView: View {
    @Environment(AppStore.self) private var store
    @State private var showingMeasurement = false
    @State private var showingHistory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back, Athlete").font(.largeTitle.bold())
                        Text("Current Evolution Stage").foregroundStyle(AppTheme.secondary)
                        HStack {
                            Text("Beta \(Int(store.evolutionProgress * 100))% Complete")
                            Spacer()
                            Text("\(Int(store.evolutionProgress * 100))%").foregroundStyle(AppTheme.cyan)
                        }
                        ProgressView(value: store.evolutionProgress)
                            .tint(AppTheme.cyan)
                    }

                    Panel {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Current Measurements").font(.title3.bold())
                                Spacer()
                                Button { showingHistory = true } label: { Image(systemName: "clock.arrow.circlepath") }
                                    .accessibilityLabel("Measurement history")
                                Button { showingMeasurement = true } label: { Image(systemName: "pencil") }
                                    .accessibilityLabel("Update measurements")
                            }
                            if let values = store.latestMeasurement?.values {
                                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 14) {
                                    ForEach(BodyMetric.allCases) { metric in
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(metric.title).font(.caption).foregroundStyle(AppTheme.secondary)
                                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                Text(store.displayValue(metric, canonicalValue: values[metric]).formatted(.number.precision(.fractionLength(0...1))))
                                                    .font(.title2)
                                                Text(store.unit(for: metric)).font(.caption).foregroundStyle(AppTheme.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(14)
                                        .background(AppTheme.field, in: RoundedRectangle(cornerRadius: 18))
                                    }
                                }
                            }
                        }
                    }

                    HStack(spacing: 16) {
                        StatCard(symbol: "chart.line.uptrend.xyaxis", value: "\(store.workouts.count)", title: "Workouts")
                        StatCard(symbol: "flame", value: "\(store.longestStreak) days", title: "Best Streak")
                    }
                }
                .padding(24)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingMeasurement) { MeasurementEditorView() }
            .sheet(isPresented: $showingHistory) { MeasurementHistoryView() }
        }
        .appScreen()
    }
}

private struct StatCard: View {
    let symbol: String
    let value: String
    let title: String
    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: symbol)
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.gradient, in: Circle())
                Text(value).font(.title)
                Text(title).foregroundStyle(AppTheme.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MeasurementEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var text = Dictionary(uniqueKeysWithValues: BodyMetric.allCases.map { ($0, "") })
    @State private var error: String?
    @FocusState private var focused: BodyMetric?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(BodyMetric.allCases) { metric in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(metric.title).foregroundStyle(AppTheme.secondary)
                            HStack {
                                TextField("0", text: Binding(get: { text[metric] ?? "" }, set: { text[metric] = $0 }))
                                    .keyboardType(.decimalPad)
                                    .focused($focused, equals: metric)
                                Text(store.unit(for: metric)).foregroundStyle(AppTheme.secondary)
                            }
                            .padding(16)
                            .background(AppTheme.field, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    if let error { Text(error).foregroundStyle(.yellow).font(.footnote) }
                    Button("Save Update", action: save)
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(24)
            }
            .navigationTitle("Update Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } }
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focused = nil } }
            }
            .onAppear {
                guard let current = store.latestMeasurement?.values else { return }
                for metric in BodyMetric.allCases {
                    text[metric] = store.displayValue(metric, canonicalValue: current[metric]).formatted(.number.precision(.fractionLength(0...1)))
                }
            }
        }
        .appScreen()
    }

    private func save() {
        guard let system = store.profile?.unitSystem else { return }
        var values = BodyValues()
        for metric in BodyMetric.allCases {
            let normalized = (text[metric] ?? "").replacingOccurrences(of: ",", with: ".")
            guard let value = Double(normalized), value > 0, value < 10_000 else {
                error = "Enter a valid positive \(metric.title.lowercased()) value."
                return
            }
            values[metric] = store.canonicalValue(metric, displayValue: value, system: system)
        }
        store.addMeasurement(values)
        dismiss()
    }
}

struct MeasurementHistoryView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.measurements.isEmpty {
                    EmptyStateView(symbol: "ruler", title: "No Measurements", message: "Your saved updates will appear here.")
                } else {
                    List(store.measurements) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(item.date.formatted(date: .long, time: .omitted)).foregroundStyle(AppTheme.cyan)
                                Spacer()
                                if item.id == store.latestMeasurement?.id {
                                    Text("Current").font(.caption).padding(.horizontal, 10).padding(.vertical, 4).background(AppTheme.blue, in: Capsule())
                                }
                            }
                            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], alignment: .leading, spacing: 8) {
                                ForEach(BodyMetric.allCases) { metric in
                                    Text("\(metric.title): \(store.displayValue(metric, canonicalValue: item.values[metric]).formatted(.number.precision(.fractionLength(0...1)))) \(store.unit(for: metric))")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.secondary)
                                }
                            }
                        }
                        .listRowBackground(AppTheme.panel)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Measurement History")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } } }
        }
        .appScreen()
    }
}
