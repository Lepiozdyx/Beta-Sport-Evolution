import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class AppStore {
    private(set) var data = PersistedAppData()
    var lastError: String?
    var successMessage: String?

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init() {
        load()
        evaluateAchievements()
    }

    var profile: UserProfile? { data.profile }
    var measurements: [BodyMeasurement] { data.measurements.sorted { $0.date > $1.date } }
    var workouts: [WorkoutRecord] { data.workouts.sorted { $0.date > $1.date } }
    var allExercises: [ExerciseDefinition] { ExerciseCatalog.builtIn + data.customExercises }
    var hasSeenOnboarding: Bool { data.hasSeenOnboarding }
    var unlockedIDs: Set<String> { Set(data.unlocks.map(\.id)) }
    var latestMeasurement: BodyMeasurement? { measurements.first }

    var evolutionProgress: Double {
        guard let profile, let current = latestMeasurement?.values else { return 0 }
        let configured = BodyMetric.allCases.filter { profile.goals[$0] > 0 }
        guard !configured.isEmpty else { return 0 }
        let values = configured.map { metric -> Double in
            let start = profile.starting[metric]
            let goal = profile.goals[metric]
            let now = current[metric]
            guard start != goal else { return now == goal ? 1 : 0 }
            return min(max((now - start) / (goal - start), 0), 1)
        }
        return values.reduce(0, +) / Double(values.count)
    }

    func completeOnboarding() {
        data.hasSeenOnboarding = true
        save()
    }

    func createProfile(_ profile: UserProfile, firstMeasurement: BodyMeasurement) {
        data.profile = profile
        data.measurements = [firstMeasurement]
        saveAndEvaluate(message: "Your beta version is ready.")
    }

    func updateUnitSystem(_ system: UnitSystem) {
        data.profile?.unitSystem = system
        save()
    }

    func addMeasurement(_ values: BodyValues) {
        data.measurements.append(.init(values: values))
        saveAndEvaluate(message: "Measurements saved.")
    }

    func addWorkout(_ workout: WorkoutRecord) {
        data.workouts.append(workout)
        saveAndEvaluate(message: "Workout finished.")
    }

    func addCustomExercise(_ exercise: ExerciseDefinition) {
        data.customExercises.append(exercise)
        save()
    }

    func updateCustomExercise(_ exercise: ExerciseDefinition) {
        guard let index = data.customExercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        data.customExercises[index] = exercise
        save()
    }

    func deleteCustomExercise(id: String) {
        data.customExercises.removeAll { $0.id == id }
        save()
    }

    func markAnalyticsViewed() {
        guard !data.hasViewedAnalytics else { return }
        data.hasViewedAnalytics = true
        saveAndEvaluate()
    }

    func markReportShared() {
        data.hasSharedReport = true
        saveAndEvaluate()
    }

    func savePhoto(_ image: UIImage, kind: String) throws -> String {
        guard let bytes = image.jpegData(compressionQuality: 0.88) else {
            throw StoreError.photoEncoding
        }
        let filename = "\(kind)_\(UUID().uuidString).jpg"
        try bytes.write(to: photosDirectory.appendingPathComponent(filename), options: .atomic)
        if kind == "before" { data.profile?.beforePhotoFilename = filename }
        if kind == "after" { data.profile?.afterPhotoFilename = filename }
        saveAndEvaluate(message: "Photo saved on this device.")
        return filename
    }

    func deletePhotos() throws {
        let manager = FileManager.default
        for file in (try? manager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)) ?? [] {
            try manager.removeItem(at: file)
        }
        data.profile?.beforePhotoFilename = nil
        data.profile?.afterPhotoFilename = nil
        save()
    }

    func backupData() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BetaSportBackup-\(Self.dateStamp).json")
        var photos: [String: Data] = [:]
        for file in (try? FileManager.default.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)) ?? [] {
            photos[file.lastPathComponent] = try Data(contentsOf: file)
        }
        let backup = BackupEnvelope(appData: data, photos: photos)
        try encoder.encode(backup).write(to: url, options: .atomic)
        return url
    }

    func restoreData(from url: URL) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let bytes = try Data(contentsOf: url)
        let backup = try decoder.decode(BackupEnvelope.self, from: bytes)
        for file in (try? FileManager.default.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)) ?? [] {
            try FileManager.default.removeItem(at: file)
        }
        for (filename, photoData) in backup.photos {
            try photoData.write(to: photosDirectory.appendingPathComponent(filename), options: .atomic)
        }
        data = backup.appData
        saveAndEvaluate(message: "Backup restored.")
    }

    func exportReport() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BetaSportReport-\(Self.dateStamp).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            let title = "Beta Sport: Evolution Report"
            title.draw(at: CGPoint(x: 48, y: 48), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 24)])
            var y: CGFloat = 92
            let lines = reportLines()
            for line in lines {
                if y > 740 {
                    context.beginPage()
                    y = 48
                }
                line.draw(in: CGRect(x: 48, y: y, width: 516, height: 30), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 13),
                    .foregroundColor: UIColor.black
                ])
                y += 24
            }
        }
        return url
    }

    func resetAllData() throws {
        try deletePhotos()
        data = PersistedAppData(hasSeenOnboarding: true)
        save()
    }

    func displayValue(_ metric: BodyMetric, canonicalValue: Double) -> Double {
        guard profile?.unitSystem == .imperial else { return canonicalValue }
        return metric == .weight ? canonicalValue * 2.204_622_6218 : canonicalValue / 2.54
    }

    func canonicalValue(_ metric: BodyMetric, displayValue: Double, system: UnitSystem) -> Double {
        guard system == .imperial else { return displayValue }
        return metric == .weight ? displayValue / 2.204_622_6218 : displayValue * 2.54
    }

    func unit(for metric: BodyMetric) -> String {
        metric == .weight ? (profile?.unitSystem.weightUnit ?? "kg") : (profile?.unitSystem.lengthUnit ?? "cm")
    }

    func evaluateAchievements() {
        var unlocked = unlockedIDs
        var changed = false
        for achievement in AchievementCatalog.all where achievement.id != "golden_release" {
            if !unlocked.contains(achievement.id), qualifies(achievement.rule) {
                data.unlocks.append(.init(id: achievement.id, date: Date()))
                unlocked.insert(achievement.id)
                changed = true
            }
        }
        if let final = AchievementCatalog.all.last,
           !unlocked.contains(final.id),
           AchievementCatalog.all.dropLast().allSatisfy({ unlocked.contains($0.id) }),
           reachedGoalCount == configuredGoalCount,
           configuredGoalCount > 0 {
            data.unlocks.append(.init(id: final.id, date: Date()))
            changed = true
        }
        if changed { save() }
    }

    private var configuredGoalCount: Int {
        guard let profile else { return 0 }
        return BodyMetric.allCases.filter { profile.goals[$0] > 0 }.count
    }

    private var reachedGoalCount: Int {
        guard let profile, let current = latestMeasurement?.values else { return 0 }
        return BodyMetric.allCases.filter { metric in
            let start = profile.starting[metric]
            let goal = profile.goals[metric]
            guard goal > 0 else { return false }
            return goal >= start ? current[metric] >= goal : current[metric] <= goal
        }.count
    }

    private func qualifies(_ rule: AchievementRule) -> Bool {
        guard let profile else { return false }
        let current = latestMeasurement?.values ?? profile.starting
        switch rule {
        case .weightLoss(let value): return profile.starting.weight - current.weight >= value
        case .weightLossPercent(let percent):
            guard profile.starting.weight > 0 else { return false }
            return (profile.starting.weight - current.weight) / profile.starting.weight * 100 >= percent
        case .metricIncrease(let metric, let value): return current[metric] - profile.starting[metric] >= value
        case .metricDecrease(let metric, let value): return profile.starting[metric] - current[metric] >= value
        case .allGoals: return configuredGoalCount > 0 && reachedGoalCount == configuredGoalCount
        case .afterPhoto: return profile.afterPhotoFilename != nil
        case .targetWeight:
            let goal = profile.goals.weight
            guard goal > 0 else { return false }
            return goal >= profile.starting.weight ? current.weight >= goal : current.weight <= goal
        case .exerciseReps(let id, let count):
            return data.workouts.contains { $0.exerciseID == id && ($0.reps ?? 0) >= count && (id != "lunges" || (($0.sets ?? 0) >= 3 && !$0.notes.isEmpty)) }
        case .exerciseWeight(let id, let weight): return data.workouts.contains { $0.exerciseID == id && ($0.weightKG ?? 0) >= weight }
        case .exerciseDuration(let id, let seconds): return data.workouts.contains { $0.exerciseID == id && ($0.durationSeconds ?? 0) >= seconds }
        case .vacuum(let seconds, let sets): return data.workouts.contains { $0.exerciseID == "vacuum" && ($0.durationSeconds ?? 0) >= seconds && ($0.sets ?? 0) >= sets }
        case .allStrengthInWeek:
            let required = Set(ExerciseCatalog.builtIn.filter { $0.category == .strength }.map(\.id))
            return weeklyGroups().values.contains { Set($0.filter { $0.category == .strength }.map(\.exerciseID)).isSuperset(of: required) }
        case .exerciseDistance(let id, let distance): return data.workouts.contains { $0.exerciseID == id && ($0.distanceKM ?? 0) >= distance }
        case .cardioDuration(let seconds): return data.workouts.contains { $0.category == .cardio && ($0.durationSeconds ?? 0) >= seconds }
        case .cardioSessionsInWeek(let count): return weeklyGroups().values.contains { $0.filter { $0.category == .cardio }.count >= count }
        case .firstWorkout: return !data.workouts.isEmpty
        case .consecutiveDays(let days): return longestStreak >= days
        case .workoutsInMonth(let count):
            return Dictionary(grouping: data.workouts) { Calendar.current.dateComponents([.year, .month], from: $0.date) }.values.contains { $0.count >= count }
        case .activeDays(let days): return Set(data.workouts.map { Calendar.current.startOfDay(for: $0.date) }).count >= days
        case .noGapDays(let span, let maxGap): return activeSpanQualifies(span: span, maxGap: maxGap)
        case .analyticsViewed: return data.hasViewedAnalytics
        case .notesCount(let count): return data.workouts.filter { !$0.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count >= count
        case .goalsReached(let count): return reachedGoalCount >= count
        case .reportShared: return data.hasSharedReport
        case .allAchievements: return false
        }
    }

    var longestStreak: Int {
        let days = Set(data.workouts.map { Calendar.current.startOfDay(for: $0.date) }).sorted()
        var best = 0
        var current = 0
        var previous: Date?
        for day in days {
            if let previous, Calendar.current.dateComponents([.day], from: previous, to: day).day == 1 {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = day
        }
        return best
    }

    private func activeSpanQualifies(span: Int, maxGap: Int) -> Bool {
        let days = Set(data.workouts.map { Calendar.current.startOfDay(for: $0.date) }).sorted()
        guard let first = days.first, let last = days.last,
              (Calendar.current.dateComponents([.day], from: first, to: last).day ?? 0) + 1 >= span else { return false }
        return zip(days, days.dropFirst()).allSatisfy {
            (Calendar.current.dateComponents([.day], from: $0.0, to: $0.1).day ?? Int.max) <= maxGap + 1
        }
    }

    private func weeklyGroups() -> [DateComponents: [WorkoutRecord]] {
        Dictionary(grouping: data.workouts) { Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: $0.date) }
    }

    private func reportLines() -> [String] {
        guard let profile else { return ["No profile data available."] }
        let current = latestMeasurement?.values ?? profile.starting
        var lines = [
            "Generated: \(Date().formatted(date: .long, time: .shortened))",
            "Evolution progress: \(Int(evolutionProgress * 100))%",
            "Workouts: \(data.workouts.count)",
            "Longest streak: \(longestStreak) days",
            "Achievements: \(unlockedIDs.count) / \(AchievementCatalog.all.count)",
            "",
            "Current measurements"
        ]
        lines += BodyMetric.allCases.map { "\($0.title): \(current[$0].formatted(.number.precision(.fractionLength(0...1)))) \($0 == .weight ? "kg" : "cm")" }
        lines += ["", "Recent workouts"]
        lines += workouts.prefix(20).map { "\($0.date.formatted(date: .abbreviated, time: .omitted)) — \($0.exerciseName)" }
        return lines
    }

    private func saveAndEvaluate(message: String? = nil) {
        save()
        evaluateAchievements()
        successMessage = message
    }

    private func load() {
        do {
            let bytes = try Data(contentsOf: dataURL)
            data = try decoder.decode(PersistedAppData.self, from: bytes)
        } catch {
            if FileManager.default.fileExists(atPath: dataURL.path) {
                lastError = "Saved data could not be read. A new local session was opened."
            }
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
            try encoder.encode(data).write(to: dataURL, options: .atomic)
        } catch {
            lastError = "Your changes could not be saved. Please try again."
        }
    }

    private var appDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("BetaSportEvolution", isDirectory: true)
    }
    private var photosDirectory: URL {
        let url = appDirectory.appendingPathComponent("Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    private var dataURL: URL { appDirectory.appendingPathComponent("data.json") }
    private static var dateStamp: String { Date().formatted(.iso8601.year().month().day()) }
}

enum StoreError: LocalizedError {
    case photoEncoding
    var errorDescription: String? { "The selected photo could not be processed." }
}
