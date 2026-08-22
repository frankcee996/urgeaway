import SwiftUI

/// Every activity/distraction runner reports back through this — the native
/// equivalent of the `run(container, onFinish)` / `{ onExit }` contract every
/// module in `activities.js` and `distractions.js` implements. SwiftUI views
/// call `onFinish()` when the exercise naturally completes; the wrapper adds
/// an explicit exit affordance so nobody mid-urge ever feels trapped in a
/// game, exactly as the web version's comment on `activities.js` states.
protocol RunnerView: View {
    var onFinish: () -> Void { get }
}

/// Outcome values used across activity/distraction/Urge Lock check-ins.
enum Outcome: String {
    case better, aLittleBetter = "a_little_better", same, stillNeedHelp = "still_need_help"
}

struct TimerPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.bodyFont(12, weight: .semibold))
            .foregroundColor(Theme.text1)
            .padding(.horizontal, Theme.space3).padding(.vertical, 6)
            .background(Theme.bg3)
            .clipShape(Capsule())
    }
}

struct PromptText: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.bodyFont(16, weight: .semibold))
            .foregroundColor(Theme.text0)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.space4)
    }
}

struct FeedbackFlash: View {
    let text: String
    let good: Bool
    var body: some View {
        Text(text)
            .font(Theme.bodyFont(13, weight: .semibold))
            .foregroundColor(text.isEmpty ? .clear : (good ? Theme.green : Theme.coral))
            .frame(height: 18)
    }
}

/// A single 2x2/4x4-style option button used by Number/Pattern challenges.
struct OptionCard: View {
    let title: String
    let disabled: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.displayFont(20, weight: .heavy))
                .foregroundColor(Theme.text0)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Theme.bg2)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusM).stroke(Theme.line, lineWidth: 1))
        }
        .disabled(disabled)
        .opacity(disabled ? 0.6 : 1)
    }
}
