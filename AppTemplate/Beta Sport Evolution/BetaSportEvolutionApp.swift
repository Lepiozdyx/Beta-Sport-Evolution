import SwiftUI

struct BetaSportEvolutionApp: View {
    @State private var store = AppStore()

    var body: some View {
        RootView()
            .environment(store)
            .preferredColorScheme(.dark)
    }
}
