import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tag(0)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }

            PlaceholderTab(title: "Daily Task", icon: "calendar")
                .tag(1)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Daily")
                }

            PlaceholderTab(title: "Statistics", icon: "chart.bar")
                .tag(2)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Graph")
                }

            PlaceholderTab(title: "Profile", icon: "person")
                .tag(3)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .tint(AppColors.tabBarActive)
    }
}

// MARK: - Placeholder for Phase 2 tabs

private struct PlaceholderTab: View {
    let title: String
    let icon: String

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))

                Text(title)
                    .font(AppFonts.sectionTitle())
                    .foregroundStyle(AppColors.textPrimary)

                Text("Coming in Phase 2")
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}
