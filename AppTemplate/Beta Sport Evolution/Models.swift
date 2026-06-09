import Foundation

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case metric
    case imperial

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var weightUnit: String { self == .metric ? "kg" : "lb" }
    var lengthUnit: String { self == .metric ? "cm" : "in" }
    var distanceUnit: String { self == .metric ? "km" : "mi" }
}

enum BodyMetric: String, Codable, CaseIterable, Identifiable {
    case weight, waist, chest, biceps, thigh

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String { self == .weight ? "scalemass" : "ruler" }
}

struct BodyValues: Codable, Equatable {
    var weight = 0.0
    var waist = 0.0
    var chest = 0.0
    var biceps = 0.0
    var thigh = 0.0

    subscript(metric: BodyMetric) -> Double {
        get {
            switch metric {
            case .weight: weight
            case .waist: waist
            case .chest: chest
            case .biceps: biceps
            case .thigh: thigh
            }
        }
        set {
            switch metric {
            case .weight: weight = newValue
            case .waist: waist = newValue
            case .chest: chest = newValue
            case .biceps: biceps = newValue
            case .thigh: thigh = newValue
            }
        }
    }
}

struct UserProfile: Codable {
    var unitSystem: UnitSystem = .metric
    var starting = BodyValues()
    var goals = BodyValues()
    var beforePhotoFilename: String?
    var afterPhotoFilename: String?
    var createdAt = Date()
}

struct BodyMeasurement: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var values = BodyValues()
}

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case strength, cardio, staticHold

    var id: String { rawValue }
    var title: String {
        switch self {
        case .strength: "Strength"
        case .cardio: "Cardio"
        case .staticHold: "Static"
        }
    }
    var symbol: String {
        switch self {
        case .strength: "dumbbell"
        case .cardio: "heart"
        case .staticHold: "stopwatch"
        }
    }
}

enum TrackingKind: String, Codable, CaseIterable {
    case strengthWeight
    case strengthReps
    case cardioDistanceTime
    case cardioTimeCount
    case cardioTimeCalories
    case staticDuration
    case staticDurationSets

    var summary: String {
        switch self {
        case .strengthWeight: "Sets, reps and weight"
        case .strengthReps: "Sets and reps"
        case .cardioDistanceTime: "Distance and time"
        case .cardioTimeCount: "Time or count"
        case .cardioTimeCalories: "Time and optional calories"
        case .staticDuration: "Duration"
        case .staticDurationSets: "Duration and sets"
        }
    }
}

struct ExerciseDefinition: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var emoji: String
    var category: ExerciseCategory
    var trackingKind: TrackingKind
    var isCustom = false
    var notes = ""
}

struct WorkoutRecord: Codable, Identifiable {
    var id = UUID()
    var exerciseID: String
    var exerciseName: String
    var category: ExerciseCategory
    var trackingKind: TrackingKind
    var date = Date()
    var sets: Int?
    var reps: Int?
    var weightKG: Double?
    var distanceKM: Double?
    var durationSeconds: Int?
    var count: Int?
    var calories: Int?
    var notes = ""

    var volume: Double {
        Double(sets ?? 1) * Double(reps ?? 0) * (weightKG ?? 0)
    }
}

enum AchievementCategory: String, Codable, CaseIterable, Identifiable {
    case transformation, strength, endurance, discipline
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum AchievementRule: Codable, Hashable {
    case weightLoss(Double)
    case weightLossPercent(Double)
    case metricIncrease(BodyMetric, Double)
    case metricDecrease(BodyMetric, Double)
    case allGoals
    case afterPhoto
    case targetWeight
    case exerciseReps(String, Int)
    case exerciseWeight(String, Double)
    case exerciseDuration(String, Int)
    case vacuum(Int, Int)
    case allStrengthInWeek
    case exerciseDistance(String, Double)
    case cardioDuration(Int)
    case cardioSessionsInWeek(Int)
    case firstWorkout
    case consecutiveDays(Int)
    case workoutsInMonth(Int)
    case activeDays(Int)
    case noGapDays(Int, Int)
    case analyticsViewed
    case notesCount(Int)
    case goalsReached(Int)
    case reportShared
    case allAchievements
}

struct AchievementDefinition: Identifiable, Hashable {
    var id: String
    var category: AchievementCategory
    var title: String
    var detail: String
    var emoji: String
    var rule: AchievementRule
}

struct AchievementUnlock: Codable, Identifiable {
    var id: String
    var date: Date
}

struct PersistedAppData: Codable {
    var profile: UserProfile?
    var measurements: [BodyMeasurement] = []
    var workouts: [WorkoutRecord] = []
    var customExercises: [ExerciseDefinition] = []
    var unlocks: [AchievementUnlock] = []
    var hasSeenOnboarding = false
    var hasViewedAnalytics = false
    var hasSharedReport = false
}

struct BackupEnvelope: Codable {
    var version = 1
    var exportedAt = Date()
    var appData: PersistedAppData
    var photos: [String: Data]
}
