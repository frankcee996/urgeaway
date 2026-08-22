import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch router.selectedTab {
                case .home: HomeView()
                case .activities: ActivitiesTabView()
                case .progress: ProgressTabView()
                case .journal: JournalTabView()
                case .settings: SettingsTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 62)

            tabBar
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $router.showUrgeMode) { UrgeModeView() }
        .fullScreenCover(item: $router.launchedActivity) { activity in
            ActivityRunnerScreen(activity: activity)
        }
        .sheet(isPresented: $router.showDashboard) { AccountView() }
        .sheet(isPresented: $router.showNotifications) { NotificationsHistoryView() }
        .sheet(isPresented: $router.showSupport) { SupportView() }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabItem(.home, "house", "Home")
            tabItem(.activities, "square.grid.2x2", "Activities")
            tabItem(.progress, "chart.bar", "Progress")
            tabItem(.journal, "book", "Journal")
            tabItem(.settings, "gearshape", "Settings")
        }
        .padding(.top, 8).padding(.bottom, 22)
        .background(Theme.bg2.opacity(0.98).ignoresSafeArea(edges: .bottom))
        .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .top)
    }

    private func tabItem(_ tab: AppTab, _ icon: String, _ label: String) -> some View {
        Button { router.selectedTab = tab } label: {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(Theme.bodyFont(10, weight: .medium))
            }
            .foregroundColor(router.selectedTab == tab ? Theme.cyan : Theme.text3)
            .frame(maxWidth: .infinity)
        }
    }
}
