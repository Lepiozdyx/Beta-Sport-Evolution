import Charts
import SwiftUI

enum AnalyticsPeriod: String, CaseIterable, Hashable {
    case week, month, year, all
    var title: String { self == .all ? "All" : rawValue.capitalized }
    var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .week: return calendar.date(byAdding: .day, value: -7, to: Date())
        case .month: return calendar.date(byAdding: .month, value: -1, to: Date())
        case .year: return calendar.date(byAdding: .year, value: -1, to: Date())
        case .all: return nil
        }
    }

    var axisComponent: Calendar.Component {
        switch self {
        case .week: .day
        case .month: .weekOfYear
        case .year: .month
        case .all: .year
        }
    }

    var axisFormat: Date.FormatStyle {
        switch self {
        case .week: .dateTime.weekday(.abbreviated)
        case .month: .dateTime.day().month(.abbreviated)
        case .year: .dateTime.month(.abbreviated).year(.twoDigits)
        case .all: .dateTime.year()
        }
    }
}

enum StrengthMetric: String, CaseIterable, Hashable {
    case reps, weight, volume
    var title: String { rawValue.capitalized }
}

struct EvolutionView: View {
    @Environment(AppStore.self) private var store
    @State private var period: AnalyticsPeriod = .month
    @State private var strengthMetric: StrengthMetric = .reps
    @State private var selectedExerciseID = "bench_press"

    private var measurements: [BodyMeasurement] {
        guard let startDate = period.startDate else {
            return store.measurements.sorted { $0.date < $1.date }
        }
        return store.measurements.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
    }
    private var workouts: [WorkoutRecord] {
        guard let startDate = period.startDate else {
            return store.workouts.sorted { $0.date < $1.date }
        }
        return store.workouts.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
    }
    private var strengthExercises: [ExerciseDefinition] {
        store.allExercises.filter { exercise in
            exercise.category == .strength && workouts.contains { $0.exerciseID == exercise.id }
        }
    }
    private var selectedWorkouts: [WorkoutRecord] { workouts.filter { $0.exerciseID == selectedExerciseID } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Evolution").font(.largeTitle.bold())
                    SegmentedPill(values: AnalyticsPeriod.allCases, selection: $period, title: \.title)

                    analyticsPanel(title: "Body Analytics") {
                        if measurements.isEmpty {
                            compactEmpty("Add measurements to see body progress.")
                        } else {
                            Chart(measurements) { point in
                                LineMark(x: .value("Date", point.date), y: .value("Weight", store.displayValue(.weight, canonicalValue: point.values.weight)))
                                PointMark(x: .value("Date", point.date), y: .value("Weight", store.displayValue(.weight, canonicalValue: point.values.weight)))
                            }
                            .foregroundStyle(AppTheme.blue)
                            .chartYAxisLabel(store.unit(for: .weight))
                            .chartXScale(domain: chartDomain(for: measurements.map(\.date)))
                            .chartXAxis { timeAxis }
                            .frame(height: 220)
                        }
                    }

                    analyticsPanel(title: "Strength Analytics") {
                        SegmentedPill(values: StrengthMetric.allCases, selection: $strengthMetric, title: \.title)
                        if strengthExercises.isEmpty {
                            compactEmpty("Record a strength workout to unlock this chart.")
                        } else {
                            Picker("Exercise", selection: $selectedExerciseID) {
                                ForEach(strengthExercises) { Text($0.name).tag($0.id) }
                            }
                            .pickerStyle(.menu)
                            Chart(selectedWorkouts) { workout in
                                let value = strengthValue(workout)
                                LineMark(x: .value("Date", workout.date), y: .value(strengthMetric.title, value))
                                PointMark(x: .value("Date", workout.date), y: .value(strengthMetric.title, value))
                            }
                            .foregroundStyle(AppTheme.cyan)
                            .chartXScale(domain: chartDomain(for: selectedWorkouts.map(\.date)))
                            .chartXAxis { timeAxis }
                            .frame(height: 220)
                        }
                    }

                    analyticsPanel(title: "Endurance Analytics") {
                        let totals = enduranceTotals
                        if totals.isEmpty {
                            compactEmpty("Record cardio distance to see endurance totals.")
                        } else {
                            Chart(totals, id: \.name) { item in
                                BarMark(x: .value("Distance", item.value), y: .value("Exercise", item.name))
                                    .foregroundStyle(AppTheme.mint)
                                    .cornerRadius(4)
                            }
                            .chartXAxisLabel(store.profile?.unitSystem.distanceUnit ?? "km")
                            .chartXScale(domain: 0...enduranceAxisMaximum)
                            .frame(maxWidth: 270, alignment: .leading)
                            .frame(height: max(150, CGFloat(totals.count * 48)))
                        }
                    }

                    analyticsPanel(title: "Goal Completion") {
                        let goals = goalProgress
                        if goals.isEmpty {
                            compactEmpty("Set body goals to track your release progress.")
                        } else {
                            HStack {
                                ForEach(goals, id: \.metric) { item in
                                    VStack {
                                        ZStack {
                                            Circle().stroke(AppTheme.field, lineWidth: 10)
                                            Circle()
                                                .trim(from: 0, to: item.progress)
                                                .stroke(AppTheme.cyan, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                                .rotationEffect(.degrees(-90))
                                            Text("\(Int(item.progress * 100))%").font(.caption.bold())
                                        }
                                        .frame(width: 76, height: 76)
                                        Text(item.metric.title).font(.caption).foregroundStyle(AppTheme.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationBarHidden(true)
            .onAppear {
                store.markAnalyticsViewed()
                if !strengthExercises.contains(where: { $0.id == selectedExerciseID }), let first = strengthExercises.first {
                    selectedExerciseID = first.id
                }
            }
            .onChange(of: period) { _, _ in
                if !strengthExercises.contains(where: { $0.id == selectedExerciseID }), let first = strengthExercises.first {
                    selectedExerciseID = first.id
                }
            }
        }
        .appScreen()
    }

    private func analyticsPanel<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        Panel {
            VStack(alignment: .leading, spacing: 18) {
                Text(title).font(.title3.bold())
                content()
            }
        }
    }

    private func compactEmpty(_ message: String) -> some View {
        Label(message, systemImage: "chart.xyaxis.line")
            .font(.subheadline)
            .foregroundStyle(AppTheme.secondary)
            .frame(maxWidth: .infinity, minHeight: 120)
    }

    private var timeAxis: some AxisContent {
        AxisMarks(values: .stride(by: period.axisComponent)) { value in
            AxisGridLine()
            AxisTick()
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(date, format: period.axisFormat)
                }
            }
        }
    }

    private func chartDomain(for dates: [Date]) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let end = Date()
        let minimumStart = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        let requestedStart = period.startDate ?? dates.min() ?? minimumStart
        let start = min(requestedStart, minimumStart)
        return start...end
    }

    private func strengthValue(_ workout: WorkoutRecord) -> Double {
        switch strengthMetric {
        case .reps:
            return Double(workout.reps ?? 0)
        case .weight:
            let kg = workout.weightKG ?? 0
            return store.profile?.unitSystem == .imperial ? kg * 2.204_622_6218 : kg
        case .volume:
            let kg = workout.volume
            return store.profile?.unitSystem == .imperial ? kg * 2.204_622_6218 : kg
        }
    }

    private var enduranceTotals: [(name: String, value: Double)] {
        let distanceWorkouts = workouts.filter { $0.category == .cardio && ($0.distanceKM ?? 0) > 0 }
        return Dictionary(grouping: distanceWorkouts, by: \.exerciseName)
            .map { name, records in
                let km = records.compactMap(\.distanceKM).reduce(0, +)
                return (name, store.profile?.unitSystem == .imperial ? km / 1.609_344 : km)
            }
            .sorted { $0.value > $1.value }
    }

    private var enduranceAxisMaximum: Double {
        max((enduranceTotals.map(\.value).max() ?? 0) * 1.12, 1)
    }

    private var goalProgress: [(metric: BodyMetric, progress: Double)] {
        guard let profile = store.profile, let current = store.latestMeasurement?.values else { return [] }
        return BodyMetric.allCases.compactMap { metric in
            let start = profile.starting[metric]
            let goal = profile.goals[metric]
            guard goal > 0, start != goal else { return nil }
            return (metric, min(max((current[metric] - start) / (goal - start), 0), 1))
        }
    }
}
