import SwiftUI

struct SettingsTabView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var auth: AuthService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.space4) {
                    Text("Settings").font(Theme.displayFont(24)).foregroundColor(Theme.text0)

                    group("Account") {
                        row(icon: "person.crop.circle", tint: Theme.cyan, title: "Account",
                            desc: auth.currentUser != nil ? (store.profileName.isEmpty ? (auth.currentUser?.email ?? "Signed in") : store.profileName) : "Sign in, profile, notifications") {
                            router.showDashboard = true
                        }
                        if auth.currentUser != nil {
                            row(icon: "arrow.right.square", tint: Theme.coral, title: "Log Out", desc: "Sign out of this device") {
                                try? auth.signOut()
                            }
                        }
                    }

                    group("Preferences") {
                        NavigationLink(destination: AppearanceSubview()) {
                            rowLabel(icon: "paintpalette", tint: Theme.green, title: "Appearance", desc: "Light, dark, or match your device")
                        }
                        NavigationLink(destination: NotificationsSubview()) {
                            rowLabel(icon: "bell", tint: Theme.amber, title: "Notifications & Reminders", desc: "Gentle nudges, haptics, custom reminders")
                        }
                        NavigationLink(destination: UrgeLockSubview()) {
                            rowLabel(icon: "lock", tint: Theme.cyan, title: "Urge Lock", desc: "Guided Access setup for 7-10 intensity urges")
                        }
                    }

                    group("Personal") {
                        NavigationLink(destination: ReasonsSubview()) {
                            rowLabel(icon: "pencil", tint: Theme.coral, title: "My Reasons", desc: "Why this matters to you")
                        }
                        NavigationLink(destination: ReachOutSubview()) {
                            rowLabel(icon: "bubble.left.and.bubble.right", tint: Theme.cyan, title: "Reach Out", desc: "Your trusted contact")
                        }
                        NavigationLink(destination: ProtectingSubview()) {
                            rowLabel(icon: "shield", tint: Theme.green, title: "What You're Protecting", desc: "Shown next to your streak on Home")
                        }
                    }

                    group("Data") {
                        NavigationLink(destination: PrivacyDataSubview()) {
                            rowLabel(icon: "lock.shield", tint: Theme.cyan, title: "Privacy & Your Data", desc: "What we store, export, or clear")
                        }
                    }

                    group("More") {
                        row(icon: "lifepreserver", tint: Theme.amber, title: "Get Support", desc: "Resources beyond this app") {
                            router.showSupport = true
                        }
                        NavigationLink(destination: AboutSubview()) {
                            rowLabel(icon: "info.circle", tint: Theme.green, title: "About UrgeAway", desc: "Version & disclaimer")
                        }
                    }
                }.padding(Theme.space4)
            }
            .background(Theme.bg1.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    @ViewBuilder private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(Theme.bodyFont(11, weight: .semibold)).foregroundColor(Theme.text2)
            VStack(spacing: 0) { content() }.cardBackground()
        }
    }

    private func row(icon: String, tint: Color, title: String, desc: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { rowLabel(icon: icon, tint: tint, title: title, desc: desc) }
    }

    private func rowLabel(icon: String, tint: Color, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(tint).frame(width: 32, height: 32).background(tint.opacity(0.14)).clipShape(RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(Theme.bodyFont(14, weight: .semibold)).foregroundColor(Theme.text0)
                Text(desc).font(Theme.bodyFont(11)).foregroundColor(Theme.text2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Theme.text3)
        }.padding(.vertical, 10)
    }
}

/// Wraps a subview's content with a consistent back-nav header.
struct SettingsSubviewScaffold<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space3) { content }
                .padding(Theme.space4)
        }
        .background(Theme.bg1.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

func settingsSectionTitle(_ text: String) -> some View {
    Text(text).font(Theme.bodyFont(11.5, weight: .semibold)).foregroundColor(Theme.text2)
}
