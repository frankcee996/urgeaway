import SwiftUI

enum AppTab: Hashable { case home, activities, progress, journal, settings }

/// Central navigation state — the native equivalent of the small router in
/// app.js (`goToTab`, `openUrgeMode`, `launchActivity`, `openSupport`, etc).
/// SwiftUI's own `NavigationStack`/`.sheet`/`.fullScreenCover` replace the
/// DOM screen-swapping that file did, but the same set of "openable things"
/// is preserved here so every entry point from Home/Settings routes through
/// one place, exactly as the web app does.
@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var showUrgeMode = false
    @Published var showDashboard = false
    @Published var showNotifications = false
    @Published var showSupport = false
    @Published var launchedActivity: ActivityDefinition?

    func launchActivity(_ activity: ActivityDefinition) {
        launchedActivity = activity
    }
}
