import SwiftUI

struct AccountView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var error: String?
    @State private var busy = false
    @State private var askForName = false

    enum Mode { case login, signup }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.space4) {
                    if !auth.isAvailable {
                        Text("Sign-in needs Firebase to be configured for this build (add GoogleService-Info.plist). Every other feature already works with zero account.")
                            .font(Theme.bodyFont(13)).foregroundColor(Theme.text2).cardBackground()
                    } else if askForName {
                        nameStep
                    } else if auth.currentUser != nil {
                        DashboardView()
                    } else {
                        formView
                    }
                }.padding(Theme.space4)
            }
            .background(Theme.bg1.ignoresSafeArea())
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }

    private var nameStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill").font(.system(size: 44)).foregroundColor(Theme.cyan)
            Text("What should we call you?").font(Theme.displayFont(18)).foregroundColor(Theme.text0)
            Text("Shown on your dashboard — never shared.").font(Theme.bodyFont(12.5)).foregroundColor(Theme.text2)
            TextField("Your name", text: $email).textFieldStyle(.plain)
                .padding(12).background(Theme.bg2).clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusS).stroke(Theme.line, lineWidth: 1)).foregroundColor(Theme.text0)
            Button("Continue") { if !email.isEmpty { store.setProfileName(email) }; askForName = false; email = "" }
                .buttonStyle(PrimaryButtonStyle())
            Button("Skip for now") { askForName = false; email = "" }.buttonStyle(GhostButtonStyle())
        }.frame(maxWidth: 300)
    }

    private var formView: some View {
        VStack(spacing: Theme.space3) {
            Picker("Mode", selection: $mode) {
                Text("Log In").tag(Mode.login)
                Text("Sign Up").tag(Mode.signup)
            }.pickerStyle(.segmented)

            labeledField(icon: "envelope", placeholder: "Email") {
                TextField("Email", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
            }
            labeledField(icon: "lock", placeholder: "Password") {
                HStack {
                    if showPassword { TextField("Password", text: $password) } else { SecureField("Password", text: $password) }
                    Button { showPassword.toggle() } label: { Image(systemName: showPassword ? "eye.slash" : "eye").foregroundColor(Theme.text2) }
                }
            }
            if let error { Text(error).font(Theme.bodyFont(12)).foregroundColor(Theme.coral) }

            Button(mode == .login ? "Log In" : "Sign Up") { submit() }
                .buttonStyle(PrimaryButtonStyle()).disabled(busy)

            if mode == .login {
                Button("Forgot password?") { Task { try? await auth.sendPasswordReset(email: email) } }
                    .font(Theme.bodyFont(12)).foregroundColor(Theme.cyan)
            }
            Text("Sign-in is never required — every core feature already works with zero account.")
                .font(Theme.bodyFont(11)).foregroundColor(Theme.text3).multilineTextAlignment(.center)
        }
    }

    private func labeledField<Content: View>(icon: String, placeholder: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(Theme.text2).frame(width: 20)
            content()
        }.padding(12).background(Theme.bg2).clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
            .overlay(RoundedRectangle(cornerRadius: Theme.radiusS).stroke(Theme.line, lineWidth: 1)).foregroundColor(Theme.text0)
    }

    private func submit() {
        error = nil; busy = true
        Task {
            do {
                if mode == .signup { try await auth.signUp(email: email, password: password); await MainActor.run { askForName = true } }
                else { try await auth.logIn(email: email, password: password) }
            } catch {
                await MainActor.run { self.error = error.localizedDescription }
            }
            await MainActor.run { busy = false }
        }
    }
}
