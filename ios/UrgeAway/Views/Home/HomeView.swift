import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var router: AppRouter
    @State private var showNotifBanner = !UserDefaults.standard.bool(forKey: "urgeaway:notif_banner_shown_local")

    private var quickOptions: [(label: String, desc: String, icon: String, tint: Color, action: () -> Void)] {
        [
            ("Distract me", "A light game", "square.grid.2x2", Theme.cyan, { router.launchActivity(randomFrom("distract")) }),
            ("Calm me down", "Breathe & ground", "wind", Theme.green, { router.launchActivity(randomFrom("calm")) }),
            ("Help me reset", "Focus reset", "arrow.clockwise", Theme.green, { router.launchActivity(activity(byId: "focus_reset")!) }),
            ("Let me write", "Private journal", "pencil", Theme.coral, { router.selectedTab = .journal }),
            ("Challenge me", "Attention task", "scope", Theme.amber, { router.launchActivity(randomFrom("challenge")) }),
            ("Reach out", "One tap message", "bubble.left.and.bubble.right", Theme.coral, { ReachOutHelper.trigger(store: store) }),
        ]
    }
    private func randomFrom(_ category: String) -> ActivityDefinition { activities(inCategory: category).randomElement()! }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.space4) {
                header
                if showNotifBanner { notifBanner }
                heroSection
                Text("What do you need right now?")
                    .font(Theme.bodyFont(12, weight: .semibold)).foregroundColor(Theme.text2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Array(quickOptions.enumerated()), id: \.offset) { _, opt in
                        Button(action: opt.action) {
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12).fill(opt.tint.opacity(0.14)).frame(width: 40, height: 40)
                                    Image(systemName: opt.icon).foregroundColor(opt.tint)
                                }
                                Text(opt.label).font(Theme.bodyFont(11.5, weight: .semibold)).foregroundColor(Theme.text0)
                                Text(opt.desc).font(Theme.bodyFont(9.5)).foregroundColor(Theme.text2)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 12).cardBackground()
                        }
                    }
                }
                Spacer(minLength: Theme.space5)
                todaySection
            }.padding(Theme.space4)
        }
        .background(Theme.bg1.ignoresSafeArea())
        .onAppear { store.recordAppOpen() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button { router.showDashboard = true } label: {
                avatar
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("UrgeAway").font(Theme.bodyFont(11, weight: .semibold)).foregroundColor(Theme.text2)
                Text("A better next few minutes.").font(Theme.bodyFont(13, weight: .medium)).foregroundColor(Theme.text1)
            }
            Spacer()
            Button { router.showNotifications = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell").foregroundColor(Theme.text1).frame(width: 40, height: 40)
                    let unread = store.getUnreadNotifCount()
                    if unread > 0 {
                        Text("\(unread)").font(.system(size: 10, weight: .heavy)).foregroundColor(.white)
                            .padding(3).background(Theme.coral).clipShape(Circle())
                            .offset(x: 4, y: -2)
                    }
                }
            }
        }
    }

    private var avatar: some View {
        let initial = (store.profileName.first ?? Character(" ")).uppercased()
        return ZStack {
            if store.profileName.isEmpty {
                Circle().fill(Theme.bg3)
                Image(systemName: "person.fill").foregroundColor(Theme.text1)
            } else {
                Circle().fill(LinearGradient(colors: [Theme.cyan, Theme.green], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text(initial).font(Theme.displayFont(15)).foregroundColor(Theme.bg0)
            }
        }.frame(width: 40, height: 40)
    }

    private var notifBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "bell").foregroundColor(Theme.cyan)
            VStack(alignment: .leading, spacing: 4) {
                Text("Turn on notifications").font(Theme.bodyFont(13, weight: .semibold)).foregroundColor(Theme.text0)
                Text("Get gentle daily reminders and occasional updates from UrgeAway.")
                    .font(Theme.bodyFont(11.5)).foregroundColor(Theme.text2)
                Button("Turn on") {
                    UserDefaults.standard.set(true, forKey: "urgeaway:notif_banner_shown_local")
                    showNotifBanner = false
                    router.selectedTab = .settings
                }.buttonStyle(.borderedProminent).controlSize(.small).tint(Theme.cyanDim)
            }
            Spacer()
            Button { UserDefaults.standard.set(true, forKey: "urgeaway:notif_banner_shown_local"); showNotifBanner = false } label: {
                Image(systemName: "xmark").foregroundColor(Theme.text2)
            }
        }.padding(Theme.space3).cardBackground()
    }

    private var heroSection: some View {
        VStack(spacing: 10) {
            WaveShape().stroke(LinearGradient(colors: [Theme.cyan, Theme.green], startPoint: .leading, endPoint: .trailing), lineWidth: 4)
                .frame(height: 40)
            Button { router.showUrgeMode = true } label: {
                Text("I HAVE AN URGE")
                    .font(Theme.displayFont(17, weight: .heavy))
                    .foregroundColor(Theme.bg0)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(LinearGradient(colors: [Theme.cyan, Theme.green], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous))
                    .shadow(color: Theme.cyanGlow, radius: 20, y: 8)
            }
            Text("Tap it. We'll take it from there.").font(Theme.bodyFont(12)).foregroundColor(Theme.text2)
        }
    }

    private var todaySection: some View {
        VStack(spacing: 10) {
            Text("Today").font(Theme.bodyFont(12, weight: .semibold)).foregroundColor(Theme.text2)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 0) {
                statCell("\(store.getUrgeSessionsToday().count)", "Urges handled")
                statCell("\(store.getTodaySessions().count)", "Activities completed")
                statCell("\(store.streak.count)", "Day streak")
            }
            if !store.streakProtecting.isEmpty {
                (Text("Protecting: ").foregroundColor(Theme.text2) + Text(store.streakProtecting).foregroundColor(Theme.cyan).fontWeight(.semibold))
                    .font(Theme.bodyFont(12))
            }
        }
    }
    private func statCell(_ num: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(num).font(Theme.displayFont(22)).foregroundColor(Theme.text0)
            Text(label).font(Theme.bodyFont(10.5)).foregroundColor(Theme.text2).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity)
    }
}

/// The calm cyan-to-green wave above the urge button — the signature moment
/// described in the README, ported from the inline `waveSVG()` path.
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height, mid = h / 2
        p.move(to: CGPoint(x: 0, y: mid))
        p.addCurve(to: CGPoint(x: w * 0.25, y: mid), control1: CGPoint(x: w * 0.08, y: mid - h * 0.35), control2: CGPoint(x: w * 0.16, y: mid - h * 0.35))
        p.addCurve(to: CGPoint(x: w * 0.5, y: mid), control1: CGPoint(x: w * 0.33, y: mid + h * 0.35), control2: CGPoint(x: w * 0.42, y: mid + h * 0.35))
        p.addCurve(to: CGPoint(x: w * 0.75, y: mid), control1: CGPoint(x: w * 0.58, y: mid - h * 0.35), control2: CGPoint(x: w * 0.67, y: mid - h * 0.35))
        p.addCurve(to: CGPoint(x: w, y: mid), control1: CGPoint(x: w * 0.83, y: mid + h * 0.35), control2: CGPoint(x: w * 0.92, y: mid + h * 0.35))
        return p
    }
}
