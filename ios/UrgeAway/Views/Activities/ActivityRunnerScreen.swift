import SwiftUI

/// Wraps any activity from the Activities tab / Home quick-actions with a
/// consistent header + outcome check-in. Ported from `renderActivityRunner`
/// in flows.js. Unlike the Urge Mode distraction loop, finishing here always
/// returns to wherever the person came from — there's no "urge" context to
/// keep looping on.
struct ActivityRunnerScreen: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let activity: ActivityDefinition

    @State private var startedAt = Date()
    @State private var showOutcome = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(activity.name).font(Theme.displayFont(16)).foregroundColor(Theme.text0)
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Theme.text2) }
            }.padding()
            Spacer()
            if showOutcome {
                outcomeView
            } else {
                ActivityRunnerDispatch(activityId: activity.id) { showOutcome = true }
            }
            Spacer()
        }
        .background(Theme.bg0.ignoresSafeArea())
    }

    private var outcomeView: some View {
        VStack(spacing: 18) {
            PromptText(text: "How was that?")
            VStack(spacing: 10) {
                outcomeButton("Helped", "better")
                outcomeButton("A little", "a_little_better")
                outcomeButton("Not really", "same")
            }.frame(maxWidth: 300)
        }.padding(.horizontal, Theme.space4)
    }

    private func outcomeButton(_ label: String, _ value: String) -> some View {
        Button {
            let duration = Int(Date().timeIntervalSince(startedAt))
            store.addSession(AppSession(activityId: activity.id, category: activity.category, durationSec: duration, outcome: value, fromUrgeMode: false))
            dismiss()
        } label: {
            Text(label).font(Theme.bodyFont(15, weight: .semibold)).foregroundColor(Theme.text0)
                .frame(maxWidth: .infinity).padding(.vertical, 14).cardBackground()
        }
    }
}
