import Foundation
import FirebaseAuth
import FirebaseCore

/// Native port of `Auth` (the Firebase wrapper referenced throughout
/// account.js). Email + password only: **Google Sign-In is intentionally
/// left out on iOS**, exactly as account.js's own comment documents for the
/// Android build — it has no iOS OAuth client / URL scheme configured, so
/// rather than show a button that fails, it's simply not offered. Phone
/// sign-in is also left out, matching the reference design.
///
/// Requires `GoogleService-Info.plist` to be added to the app target (see
/// README "Firebase setup"). Until it's added, `available()` returns false
/// and the app behaves exactly like the web preview does before Firebase is
/// configured: Account shows a plain notice instead of a form, and every
/// other feature works normally with zero account.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var currentUser: User?
    @Published private(set) var isAvailable: Bool = false

    private var handle: AuthStateDidChangeListenerHandle?

    private init() {
        isAvailable = FirebaseApp.app() != nil
        guard isAvailable else { return }
        currentUser = Auth.auth().currentUser
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }

    func signUp(email: String, password: String) async throws {
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func logIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
