import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: DataStore
    let onDone: () -> Void

    private struct Slide { let icon: String; let color: Color; let title: String; let body: String }
    private let slides: [Slide] = [
        .init(icon: "house", color: Theme.cyan, title: "Start with the Urge button",
              body: "When an urge hits, tap the big button on Home. UrgeAway walks you through a short, guided moment to help it pass."),
        .init(icon: "square.grid.2x2", color: Theme.green, title: "Activities, any time",
              body: "Games, breathing exercises, and short challenges to shift your focus — jump in whenever, not just mid-urge."),
        .init(icon: "chart.bar", color: Theme.amber, title: "Progress & Journal",
              body: "Progress tracks your streaks over time. Journal is a private space to reflect on hard moments — or good ones."),
        .init(icon: "gearshape", color: Theme.coral, title: "Make it yours in Settings",
              body: "Add your own reasons, set up someone to reach out to, schedule reminders, and manage your privacy — all grouped by category so it's easy to find."),
    ]
    private var chooseStep: Int { 1 + slides.count }
    private var controlStep: Int { chooseStep + 1 }
    private var totalSteps: Int { controlStep + 1 }

    @State private var step = 0
    @State private var selected: Set<String> = []

    var body: some View {
        VStack(spacing: Theme.space5) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule().fill(i == step ? Theme.cyan : Theme.bg3).frame(width: i == step ? 18 : 6, height: 6)
                }
            }.padding(.top, Theme.space5)

            Spacer()
            content
            Spacer()

            HStack(spacing: 10) {
                if step > 0 {
                    Button("Back") { step -= 1 }.buttonStyle(GhostButtonStyle(fullWidth: false)).frame(maxWidth: 100)
                }
                Button(step == controlStep ? "Get Started" : "Continue") { advance() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(step == chooseStep && selected.isEmpty)
            }
            Button("Skip") { finish() }.font(Theme.bodyFont(12.5)).foregroundColor(Theme.text2)
        }
        .padding(.horizontal, Theme.space5).padding(.bottom, Theme.space4)
        .background(Theme.bg1.ignoresSafeArea())
    }

    @ViewBuilder private var content: some View {
        if step == 0 {
            VStack(spacing: 18) {
                WaveShape().stroke(LinearGradient(colors: [Theme.cyan, Theme.green], startPoint: .leading, endPoint: .trailing), lineWidth: 4)
                    .frame(width: 140, height: 40)
                Text("Welcome to UrgeAway").font(Theme.displayFont(26)).foregroundColor(Theme.text0).multilineTextAlignment(.center)
                Text("Sometimes you don't need to solve everything. You just need something that helps you get through the moment. Here's a quick look around.")
                    .font(Theme.bodyFont(14)).foregroundColor(Theme.text2).multilineTextAlignment(.center).frame(maxWidth: 280)
            }
        } else if step >= 1 && step < chooseStep {
            let slide = slides[step - 1]
            VStack(spacing: 18) {
                ZStack { Circle().fill(slide.color.opacity(0.14)).frame(width: 64, height: 64); Image(systemName: slide.icon).foregroundColor(slide.color).font(.system(size: 26)) }
                Text(slide.title).font(Theme.displayFont(22)).foregroundColor(Theme.text0).multilineTextAlignment(.center)
                Text(slide.body).font(Theme.bodyFont(14)).foregroundColor(Theme.text2).multilineTextAlignment(.center).frame(maxWidth: 290)
            }
        } else if step == chooseStep {
            VStack(spacing: 14) {
                Text("Choose what helps you").font(Theme.displayFont(22)).foregroundColor(Theme.text0)
                Text("Pick a few to start with — you can always try the rest later.").font(Theme.bodyFont(13)).foregroundColor(Theme.text2)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(activityRegistry) { a in
                        Button {
                            if selected.contains(a.id) { selected.remove(a.id) } else { selected.insert(a.id) }
                        } label: {
                            Text(a.name).font(Theme.bodyFont(12.5, weight: .semibold))
                                .foregroundColor(selected.contains(a.id) ? Theme.bg0 : Theme.text1)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(selected.contains(a.id) ? AnyShapeStyle(Theme.cyan) : AnyShapeStyle(Theme.bg2))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        } else {
            VStack(spacing: 18) {
                ZStack { Circle().fill(Theme.cyan.opacity(0.14)).frame(width: 64, height: 64); Image(systemName: "shield").foregroundColor(Theme.cyan).font(.system(size: 26)) }
                Text("You're in control").font(Theme.displayFont(22)).foregroundColor(Theme.text0)
                Text("UrgeAway provides optional tools — distraction, grounding, reflection — and doesn't replace professional support. Your data stays on this device.")
                    .font(Theme.bodyFont(14)).foregroundColor(Theme.text2).multilineTextAlignment(.center).frame(maxWidth: 290)
            }
        }
    }

    private func advance() {
        if step == controlStep { finish() } else { step += 1 }
    }
    private func finish() {
        store.setOnboarded(preferredActivities: Array(selected))
        onDone()
    }
}

/// Shown first, before onboarding, unless already signed in or already
/// skipped once. Ported from `renderLoginGate` — skipping is always one tap
/// away, nothing here blocks use of the app.
struct LoginGateView: View {
    @EnvironmentObject var store: DataStore
    let onDone: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            AccountView()
            Button("Skip for now") { store.setLoginPromptShown(); onDone() }
                .buttonStyle(GhostButtonStyle()).padding(Theme.space4)
        }.background(Theme.bg1.ignoresSafeArea())
    }
}
