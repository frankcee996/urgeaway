import SwiftUI

/// Ported from `UrgeLock.renderConfirm` in urgelock.js. Shown after picking
/// an intensity of 7-10 in Urge Mode's pre-distraction step.
///
/// iOS has no equivalent to Android's `Activity#startLockTask()` — Apple
/// does not let any app lock itself to the screen. Only the person can do
/// that, manually, via Guided Access (Settings → Accessibility → Guided
/// Access, then a triple-click). This view says so plainly rather than
/// implying an in-app "set up" path that doesn't exist, exactly as the
/// product README documents.
struct UrgeLockConfirmView: View {
    @EnvironmentObject var store: DataStore
    let intensity: Int
    let onCancel: () -> Void
    @State private var launch = false

    private var durationLabel: String {
        let sec = store.getUrgeLockDurationSec(intensity: intensity) ?? 0
        let min = Int((Double(sec) / 60).rounded())
        return "\(min) minute\(min == 1 ? "" : "s")"
    }

    var body: some View {
        if launch {
            UrgeLockSessionView(intensity: intensity)
        } else {
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Theme.cyan.opacity(0.14)).frame(width: 60, height: 60)
                    Image(systemName: "lock.fill").foregroundColor(Theme.cyan)
                }
                Text("Urge Lock").font(Theme.displayFont(18)).foregroundColor(Theme.text0)
                VStack(spacing: 4) {
                    Text("Your urge: **\(intensity)/10**")
                    Text("Lock duration: **\(durationLabel)**")
                }.font(Theme.bodyFont(14.5)).foregroundColor(Theme.text1).multilineTextAlignment(.center)

                Text("UrgeAway will start a focused timed session. iOS doesn\u2019t let any app lock itself to the screen the way Android does — if you\u2019ve turned on Guided Access (Settings \u2192 Accessibility \u2192 Guided Access), you can triple-click the side button yourself once the session starts to stay locked in.")
                    .font(Theme.bodyFont(12.5)).foregroundColor(Theme.text2).multilineTextAlignment(.center)

                Button("START URGE LOCK") { launch = true }.buttonStyle(PrimaryButtonStyle())
                Button("CANCEL", action: onCancel).buttonStyle(GhostButtonStyle())
            }
            .padding(.horizontal, Theme.space5)
            .frame(maxWidth: 290)
        }
    }
}

/// The locked session itself: slim header with live countdown, distraction
/// loop underneath. Timestamp-based (`endTime - now`), so it survives the
/// app being suspended and relaunched, exactly like the web version.
struct UrgeLockSessionView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let intensity: Int

    @State private var kind: DistractionKind = DistractionPicker.pickRandom()
    @State private var remaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var complete = false
    @State private var feeling: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(complete ? "Urge Lock Complete" : "\u{1F512} Urge Lock").font(Theme.displayFont(15)).foregroundColor(Theme.text0)
                Spacer()
                if !complete {
                    Text(formatClock(remaining)).font(.system(size: 16, weight: .semibold).monospacedDigit()).foregroundColor(Theme.text0)
                }
            }.padding()
            if !complete {
                Text("Stay with this moment.").font(Theme.bodyFont(12.5)).foregroundColor(Theme.text2)
            }
            Spacer()
            if complete {
                completeView
            } else {
                DistractionRunnerDispatch(kind: kind) { kind = DistractionPicker.pickRandom() }
            }
            Spacer()
        }
        .background(Theme.bg0.ignoresSafeArea())
        .onAppear(perform: start)
        .onDisappear { timer?.invalidate() }
    }

    private func start() {
        var session = store.urgeLockSession
        if session == nil || session?.status != "active" {
            session = store.startUrgeLockSession(intensity: intensity)
        }
        guard let s = session else { return }
        tick(s)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in tick(s) }
        // No programmatic screen-pinning API exists on iOS. The confirm
        // screen already explained Guided Access; this is just a nudge.
        NotificationCenter.default.post(name: .urgeAwayToast, object: "Triple-click now if you\u2019ve set up Guided Access")
    }

    private func tick(_ session: UrgeLockSession) {
        let ms = session.endTime.timeIntervalSinceNow
        if ms <= 0 { finish(session) } else { remaining = ms }
    }

    private func finish(_ session: UrgeLockSession) {
        timer?.invalidate()
        store.completeUrgeLockSession(feeling: nil)
        complete = true
    }

    private var completeView: some View {
        VStack(spacing: 18) {
            PromptText(text: "You made it through the session.")
            Text("How are you feeling now?").font(Theme.bodyFont(13)).foregroundColor(Theme.text2)
            VStack(spacing: 10) {
                outcomeButton("Better", "better")
                outcomeButton("Still having an urge", "still_having_urge")
                outcomeButton("The urge is gone", "urge_gone")
            }.frame(maxWidth: 320)
        }.padding(.horizontal, Theme.space4)
    }

    private func outcomeButton(_ label: String, _ value: String) -> some View {
        Button {
            store.completeUrgeLockSession(feeling: value)
            store.addSession(AppSession(
                activityId: "urge-lock", category: "urge-lock",
                durationSec: store.urgeLockSession?.durationSec ?? 0,
                outcome: (value == "better" || value == "urge_gone") ? "better" : "still_need_help",
                fromUrgeMode: true, intensity: intensity))
            store.clearUrgeLockSession()
            if value == "still_having_urge" {
                NotificationCenter.default.post(name: .urgeAwayToast, object: "Okay — let\u2019s try something else.")
                complete = false
                kind = DistractionPicker.pickRandom()
            } else {
                NotificationCenter.default.post(name: .urgeAwayToast, object: "Logged. Nice work staying with it.")
                dismiss()
            }
        } label: {
            Text(label).font(Theme.bodyFont(15, weight: .semibold)).foregroundColor(Theme.text0)
                .frame(maxWidth: .infinity).padding(.vertical, 14).cardBackground()
        }
    }
}

private func formatClock(_ interval: TimeInterval) -> String {
    let total = max(0, Int(interval.rounded(.up)))
    return String(format: "%d:%02d", total / 60, total % 60)
}

extension Notification.Name {
    static let urgeAwayToast = Notification.Name("urgeAwayToast")
}
