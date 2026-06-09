import Foundation

enum ExerciseCatalog {
    static let builtIn: [ExerciseDefinition] = [
        .init(id: "bench_press", name: "Bench Press", emoji: "🏋️", category: .strength, trackingKind: .strengthWeight),
        .init(id: "squat", name: "Squat", emoji: "💪", category: .strength, trackingKind: .strengthWeight),
        .init(id: "deadlift", name: "Deadlift", emoji: "⚡", category: .strength, trackingKind: .strengthWeight),
        .init(id: "pull_ups", name: "Pull-ups", emoji: "🤸", category: .strength, trackingKind: .strengthReps),
        .init(id: "push_ups", name: "Push-ups", emoji: "👊", category: .strength, trackingKind: .strengthReps),
        .init(id: "lunges", name: "Lunges", emoji: "🦵", category: .strength, trackingKind: .strengthWeight),
        .init(id: "barbell_row", name: "Barbell Row", emoji: "🏋️", category: .strength, trackingKind: .strengthWeight),
        .init(id: "seated_dumbbell_press", name: "Seated Dumbbell Press", emoji: "💪", category: .strength, trackingKind: .strengthWeight),
        .init(id: "biceps_curl", name: "Biceps Curl", emoji: "💪", category: .strength, trackingKind: .strengthWeight),
        .init(id: "triceps_extension", name: "Triceps Extension", emoji: "🏋️", category: .strength, trackingKind: .strengthWeight),
        .init(id: "running", name: "Running", emoji: "🏃", category: .cardio, trackingKind: .cardioDistanceTime),
        .init(id: "cycling", name: "Cycling", emoji: "🚴", category: .cardio, trackingKind: .cardioDistanceTime),
        .init(id: "swimming", name: "Swimming", emoji: "🏊", category: .cardio, trackingKind: .cardioDistanceTime),
        .init(id: "jump_rope", name: "Jump Rope", emoji: "🪢", category: .cardio, trackingKind: .cardioTimeCount),
        .init(id: "burpees", name: "Burpees", emoji: "💥", category: .cardio, trackingKind: .strengthReps),
        .init(id: "elliptical", name: "Elliptical", emoji: "🏃", category: .cardio, trackingKind: .cardioTimeCalories),
        .init(id: "rowing", name: "Rowing Machine", emoji: "🚣", category: .cardio, trackingKind: .cardioDistanceTime),
        .init(id: "walking", name: "Walking", emoji: "🚶", category: .cardio, trackingKind: .cardioDistanceTime),
        .init(id: "plank", name: "Plank", emoji: "🧘", category: .staticHold, trackingKind: .staticDuration),
        .init(id: "vacuum", name: "Vacuum", emoji: "🫁", category: .staticHold, trackingKind: .staticDurationSets),
        .init(id: "l_sit", name: "L-Sit Hold", emoji: "🤸", category: .staticHold, trackingKind: .staticDuration)
    ]
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        .init(id: "first_step", category: .transformation, title: "First Step", detail: "Lose 1 kg from your starting weight", emoji: "📉", rule: .weightLoss(1)),
        .init(id: "balance", category: .transformation, title: "Balance", detail: "Lose 5% of your starting weight", emoji: "⚖️", rule: .weightLossPercent(5)),
        .init(id: "light_start", category: .transformation, title: "Light Start", detail: "Lose 5 kg from your starting weight", emoji: "🔥", rule: .weightLoss(5)),
        .init(id: "steel_arms", category: .transformation, title: "Steel Arms", detail: "Add 3 cm to your biceps", emoji: "💪", rule: .metricIncrease(.biceps, 3)),
        .init(id: "colossus_chest", category: .transformation, title: "Colossus Chest", detail: "Add 5 cm to your chest", emoji: "🫁", rule: .metricIncrease(.chest, 5)),
        .init(id: "powerful_legs", category: .transformation, title: "Powerful Legs", detail: "Add 4 cm to your thigh", emoji: "🦵", rule: .metricIncrease(.thigh, 4)),
        .init(id: "wasp_waist", category: .transformation, title: "Wasp Waist", detail: "Reduce your waist by 10 cm", emoji: "🎯", rule: .metricDecrease(.waist, 10)),
        .init(id: "full_turn", category: .transformation, title: "Full Turn", detail: "Reach all configured body goals", emoji: "🔄", rule: .allGoals),
        .init(id: "before_after", category: .transformation, title: "Before & After", detail: "Add an after photo", emoji: "📸", rule: .afterPhoto),
        .init(id: "finish_line", category: .transformation, title: "Finish Line", detail: "Reach your target weight", emoji: "🏁", rule: .targetWeight),

        .init(id: "first_rep", category: .strength, title: "First Rep", detail: "Complete one pull-up", emoji: "🪜", rule: .exerciseReps("pull_ups", 1)),
        .init(id: "pullup_master", category: .strength, title: "Pull-up Master", detail: "Complete 10 pull-ups in one set", emoji: "🧗", rule: .exerciseReps("pull_ups", 10)),
        .init(id: "bench_beginner", category: .strength, title: "Bench Beginner", detail: "Bench press 50 kg", emoji: "🏋️", rule: .exerciseWeight("bench_press", 50)),
        .init(id: "bench_legend", category: .strength, title: "Bench Press Legend", detail: "Bench press 100 kg", emoji: "🦾", rule: .exerciseWeight("bench_press", 100)),
        .init(id: "foundation", category: .strength, title: "Foundation", detail: "Squat 80 kg", emoji: "🧱", rule: .exerciseWeight("squat", 80)),
        .init(id: "liftoff", category: .strength, title: "Lift Off", detail: "Squat 120 kg", emoji: "🚀", rule: .exerciseWeight("squat", 120)),
        .init(id: "fast_start", category: .strength, title: "Fast Start", detail: "Complete 20 push-ups in one set", emoji: "⚡", rule: .exerciseReps("push_ups", 20)),
        .init(id: "steel_endurance", category: .strength, title: "Steel Endurance", detail: "Complete 50 push-ups in one set", emoji: "🔥", rule: .exerciseReps("push_ups", 50)),
        .init(id: "precision", category: .strength, title: "Precision", detail: "Record 3 sets of lunges with a technique note", emoji: "🎯", rule: .exerciseReps("lunges", 1)),
        .init(id: "motionless", category: .strength, title: "Motionless", detail: "Hold a plank for 5 minutes", emoji: "🧘", rule: .exerciseDuration("plank", 300)),
        .init(id: "vacuum_master", category: .strength, title: "Vacuum Master", detail: "Complete 5 vacuum sets of 30 seconds", emoji: "🌀", rule: .vacuum(30, 5)),
        .init(id: "combo_strike", category: .strength, title: "Combo Strike", detail: "Complete every strength exercise in one week", emoji: "💥", rule: .allStrengthInWeek),

        .init(id: "first_km", category: .endurance, title: "First Kilometer", detail: "Run 1 km", emoji: "🚶", rule: .exerciseDistance("running", 1)),
        .init(id: "five_k", category: .endurance, title: "5K Finish", detail: "Run 5 km", emoji: "🎯", rule: .exerciseDistance("running", 5)),
        .init(id: "half_marathon", category: .endurance, title: "Half Marathon", detail: "Run 10 km in one workout", emoji: "🦵", rule: .exerciseDistance("running", 10)),
        .init(id: "marathon", category: .endurance, title: "Marathon Runner", detail: "Run 21 km in one workout", emoji: "🏁", rule: .exerciseDistance("running", 21)),
        .init(id: "dragon_breath", category: .endurance, title: "Dragon Breath", detail: "Complete 30 minutes of cardio", emoji: "⏱️", rule: .cardioDuration(1_800)),
        .init(id: "water_element", category: .endurance, title: "Water Element", detail: "Swim 1 km", emoji: "🌊", rule: .exerciseDistance("swimming", 1)),
        .init(id: "cyclist", category: .endurance, title: "Cyclist", detail: "Cycle 20 km", emoji: "🚴", rule: .exerciseDistance("cycling", 20)),
        .init(id: "cardio_week", category: .endurance, title: "Marathon Week", detail: "Complete 5 cardio workouts in one week", emoji: "🔁", rule: .cardioSessionsInWeek(5)),

        .init(id: "first_day", category: .discipline, title: "First Day", detail: "Record your first workout", emoji: "🗓️", rule: .firstWorkout),
        .init(id: "week_warrior", category: .discipline, title: "Week Warrior", detail: "Train for 7 consecutive days", emoji: "📆", rule: .consecutiveDays(7)),
        .init(id: "evolution_month", category: .discipline, title: "Evolution Month", detail: "Complete 30 workouts in one month", emoji: "🌙", rule: .workoutsInMonth(30)),
        .init(id: "strength_quarter", category: .discipline, title: "Strength Quarter", detail: "Stay active for 90 days without a gap over 2 days", emoji: "🏆", rule: .noGapDays(90, 2)),
        .init(id: "half_year", category: .discipline, title: "Half-year Journey", detail: "Log activity on 180 days", emoji: "🌟", rule: .activeDays(180)),
        .init(id: "evolution_year", category: .discipline, title: "Evolution Year", detail: "Log activity on 365 days", emoji: "🎖️", rule: .activeDays(365)),
        .init(id: "analyst", category: .discipline, title: "Analyst", detail: "Open your analytics", emoji: "📊", rule: .analyticsViewed),
        .init(id: "journalist", category: .discipline, title: "Journalist", detail: "Add notes to 10 workouts", emoji: "📝", rule: .notesCount(10)),
        .init(id: "goal_getter", category: .discipline, title: "Goal Getter", detail: "Reach 3 configured goals", emoji: "🎯", rule: .goalsReached(3)),
        .init(id: "mentor", category: .discipline, title: "Mentor", detail: "Export and share a report", emoji: "🤝", rule: .reportShared),
        .init(id: "golden_release", category: .discipline, title: "FINAL: Release", detail: "Unlock every achievement and reach your goals", emoji: "👑", rule: .allAchievements)
    ]
}
