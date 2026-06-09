import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if !store.hasSeenOnboarding {
                OnboardingView()
            } else if store.profile == nil {
                SetupView()
            } else {
                MainTabView()
            }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { store.lastError != nil },
            set: { if !$0 { store.lastError = nil } }
        )) {
            Button("OK") { store.lastError = nil }
        } message: {
            Text(store.lastError ?? "")
        }
        .alert("Done", isPresented: Binding(
            get: { store.successMessage != nil },
            set: { if !$0 { store.successMessage = nil } }
        )) {
            Button("OK") { store.successMessage = nil }
        } message: {
            Text(store.successMessage ?? "")
        }
    }
}

private struct OnboardingPage {
    let symbol: String
    let title: String
    let message: String
    let colors: [Color]
}

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @State private var page = 0

    private let pages = [
        OnboardingPage(symbol: "waveform.path.ecg", title: "Your Body Is In Beta Testing", message: "Track every workout. Measure every improvement. Build your strongest release.", colors: [AppTheme.blue, .blue]),
        OnboardingPage(symbol: "chart.line.uptrend.xyaxis", title: "Track Real Progress", message: "See your evolution through clear, focused analytics.", colors: [AppTheme.blue, AppTheme.cyan]),
        OnboardingPage(symbol: "trophy", title: "Unlock Achievements", message: "Earn rewards for consistency and meaningful milestones.", colors: [AppTheme.cyan, .teal]),
        OnboardingPage(symbol: "bolt", title: "Build Your Golden Release", message: "Every workout brings you closer to your final form.", colors: [.yellow, .blue])
    ]

    var body: some View {
        ZStack {
            AppBackground()
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") { store.completeOnboarding() }
                        .foregroundStyle(AppTheme.secondary)
                }
                .padding(.horizontal, 24)

                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        let item = pages[index]
                        VStack(spacing: 30) {
                            Spacer()
                            Image(systemName: item.symbol)
                                .font(.system(size: 62, weight: .medium))
                                .frame(width: 132, height: 132)
                                .background(LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                                .shadow(color: item.colors.last?.opacity(0.45) ?? .clear, radius: 24)
                                .accessibilityHidden(true)
                            Text(item.title)
                                .font(.largeTitle.bold())
                                .multilineTextAlignment(.center)
                            Text(item.message)
                                .font(.title3)
                                .foregroundStyle(AppTheme.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button(page == pages.count - 1 ? "Get Started" : "Next") {
                    if page == pages.count - 1 {
                        store.completeOnboarding()
                    } else {
                        withAnimation { page += 1 }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(24)
            }
        }
        .foregroundStyle(.white)
    }
}

enum AppTab: Hashable {
    case dashboard, arena, evolution, hall, settings
}

struct MainTabView: View {
    @State private var tab: AppTab = .dashboard

    var body: some View {
        TabView(selection: $tab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house") }
                .tag(AppTab.dashboard)
            ArenaView()
                .tabItem { Label("Arena", systemImage: "dumbbell") }
                .tag(AppTab.arena)
            EvolutionView()
                .tabItem { Label("Evolution", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.evolution)
            HallOfFameView()
                .tabItem { Label("Hall of Fame", systemImage: "trophy") }
                .tag(AppTab.hall)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(AppTheme.blue)
        .toolbarBackground(AppTheme.background.opacity(0.98), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
