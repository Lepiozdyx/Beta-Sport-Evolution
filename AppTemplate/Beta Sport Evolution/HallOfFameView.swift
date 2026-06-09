import SwiftUI

struct HallOfFameView: View {
    @Environment(AppStore.self) private var store
    @State private var category: AchievementCategory = .transformation
    @State private var selected: AchievementDefinition?

    private var achievements: [AchievementDefinition] {
        AchievementCatalog.all.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Hall of Fame").font(.largeTitle.bold())
                    Panel {
                        VStack(spacing: 12) {
                            Text("🏆").font(.system(size: 42))
                            Text("Achievement Progress").foregroundStyle(AppTheme.secondary)
                            Text("\(store.unlockedIDs.count) / \(AchievementCatalog.all.count) Unlocked").font(.title)
                            ProgressView(value: Double(store.unlockedIDs.count), total: Double(AchievementCatalog.all.count))
                                .tint(.yellow)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(AchievementCategory.allCases) { item in
                                Button(item.title) { category = item }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(category == item ? AnyShapeStyle(AppTheme.gradient) : AnyShapeStyle(AppTheme.panel), in: Capsule())
                                    .foregroundStyle(category == item ? .white : AppTheme.secondary)
                            }
                        }
                    }
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 16) {
                        ForEach(achievements) { achievement in
                            let unlocked = store.unlockedIDs.contains(achievement.id)
                            Button { selected = achievement } label: {
                                VStack(spacing: 12) {
                                    Text(unlocked ? achievement.emoji : "🔒")
                                        .font(.system(size: 42))
                                        .grayscale(unlocked ? 0 : 1)
                                    Text(achievement.title)
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                    if let date = store.data.unlocks.first(where: { $0.id == achievement.id })?.date {
                                        Text(date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.blue)
                                    } else {
                                        Text("Locked").font(.caption).foregroundStyle(AppTheme.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 165)
                                .padding(12)
                                .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 24))
                                .overlay(RoundedRectangle(cornerRadius: 24).stroke(unlocked ? AppTheme.blue : AppTheme.border, lineWidth: unlocked ? 2 : 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(achievement.title), \(unlocked ? "unlocked" : "locked")")
                        }
                    }
                }
                .padding(24)
            }
            .navigationBarHidden(true)
            .sheet(item: $selected) { AchievementDetailView(achievement: $0) }
        }
        .appScreen()
    }
}

private struct AchievementDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let achievement: AchievementDefinition

    var body: some View {
        let unlockedDate = store.data.unlocks.first(where: { $0.id == achievement.id })?.date
        VStack(spacing: 22) {
            HStack { Spacer(); Button("Close", systemImage: "xmark") { dismiss() } }
            Spacer()
            Text(unlockedDate == nil ? "🔒" : achievement.emoji).font(.system(size: 72))
            Text(achievement.title).font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text(achievement.detail).font(.title3).foregroundStyle(AppTheme.secondary).multilineTextAlignment(.center)
            if let unlockedDate {
                Label("Unlocked", systemImage: "checkmark")
                    .foregroundStyle(AppTheme.blue)
                Text(unlockedDate.formatted(date: .long, time: .omitted)).foregroundStyle(AppTheme.secondary)
            } else {
                Label("Locked", systemImage: "lock").foregroundStyle(AppTheme.secondary)
            }
            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
        .appScreen()
    }
}
