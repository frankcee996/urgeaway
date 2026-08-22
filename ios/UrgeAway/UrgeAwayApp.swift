import SwiftUI
import FirebaseCore

/// Configures Firebase once at process start, if `GoogleService-Info.plist`
/// is present. Safe to run even without it — `FirebaseApp.app()` then stays
/// nil and `AuthService.isAvailable` reflects that, exactly like the web
/// version's `Auth.available()` check before Firebase is configured.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        return true
    }
}

@main
struct UrgeAwayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = DataStore.shared
    @StateObject private var router = AppRouter()
    @StateObject private var auth = AuthService.shared

    @State private var stage: LaunchStage = .splash
    enum LaunchStage { case splash, loginGate, onboarding, main }

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch stage {
                case .splash:
                    SplashView(onDone: afterSplash)
                case .loginGate:
                    LoginGateView(onDone: afterLoginGate)
                case .onboarding:
                    OnboardingView(onDone: { stage = .main })
                case .main:
                    RootTabView()
                }
            }
            .environmentObject(store)
            .environmentObject(router)
            .environmentObject(auth)
            .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch store.settings.theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private func afterSplash() {
        let signedIn = auth.currentUser != nil
        if !signedIn && !store.isLoginPromptShown() {
            stage = .loginGate
        } else {
            afterLoginGate()
        }
    }
    private func afterLoginGate() {
        stage = store.isOnboarded() ? .main : .onboarding
    }
}
