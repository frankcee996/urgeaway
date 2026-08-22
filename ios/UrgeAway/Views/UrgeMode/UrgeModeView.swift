import SwiftUI

/// The full-screen "I HAVE AN URGE" takeover. Ported from `renderUrgeMode` in
/// flows.js. Per the "no menu" design: press the button, get something
/// immediately — no category choice, no activity choice. If still having the
/// urge afterward it loops straight into another distraction, never back to
/// Home.
struct UrgeModeView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .morph
    @State private var showLine2 = false
    @State private var circleScale: CGFloat = 0
    @State private var intensity: Int?

    enum Stage { case morph, preStep, urgeLockConfirm, distractionLoop }

    var body: some View {
        ZStack {
            Theme.bg0.ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundColor(Theme.text2).padding()
                    }
                }
                Spacer()
                content
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).delay(0.2)) { circleScale = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { withAnimation { showLine2 = true } }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) { withAnimation { stage = .preStep } }
        }
    }

    @ViewBuilder private var content: some View {
        switch stage {
        case .morph:
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [Theme.green, Theme.cyan], startPoint: .top, endPoint: .bottom))
                        .frame(width: 92, height: 92).scaleEffect(circleScale).opacity(circleScale > 0 ? 0.85 : 0)
                }.frame(height: 140)
                Text(showLine2 ? "Okay. Let's get your mind somewhere else." : "You don't have to figure everything out right now.")
                    .font(Theme.bodyFont(15, weight: .medium)).foregroundColor(Theme.text1)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
                    .transition(.opacity)
            }
        case .preStep:
            PreDistractionStep(intensity: $intensity, onContinue: { chosen in
                if let n = chosen, let _ = store.getUrgeLockDurationSec(intensity: n) {
                    stage = .urgeLockConfirm
                } else {
                    stage = .distractionLoop
                }
            })
        case .urgeLockConfirm:
            UrgeLockConfirmView(intensity: intensity ?? 7, onCancel: { stage = .distractionLoop })
        case .distractionLoop:
            DistractionLoopView(intensity: intensity)
        }
    }
}

/// "Remember why" (if any reasons saved) + intensity picker, one step so it stays fast.
private struct PreDistractionStep: View {
    @EnvironmentObject var store: DataStore
    @Binding var intensity: Int?
    let onContinue: (Int?) -> Void

    var body: some View {
        VStack(spacing: 18) {
            if !store.reasons.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("REMEMBER WHY").font(Theme.bodyFont(11.5, weight: .semibold)).foregroundColor(Theme.text2)
                    ForEach(Array(store.reasons.shuffled().prefix(3)), id: \.self) { r in
                        Text(r).font(Theme.bodyFont(15, weight: .semibold)).foregroundColor(Theme.text0)
                    }
                }.frame(maxWidth: 300, alignment: .leading)
            }
            Text("How intense does this feel right now?")
                .font(Theme.bodyFont(16, weight: .semibold)).foregroundColor(Theme.text0)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                ForEach(1...10, id: \.self) { n in
                    Button { intensity = n } label: {
                        Text("\(n)")
                            .font(Theme.bodyFont(14, weight: .semibold))
                            .frame(width: 42, height: 36)
                            .foregroundColor(intensity == n ? Theme.bg0 : Theme.text1)
                            .background(intensity == n ? AnyShapeStyle(Theme.cyan) : AnyShapeStyle(Theme.bg2))
                            .clipShape(Capsule())
                    }
                }
            }.frame(maxWidth: 290)
            Button("Continue") { onContinue(intensity) }
                .buttonStyle(PrimaryButtonStyle(fullWidth: false)).frame(maxWidth: 220)
        }
        .padding(.horizontal, Theme.space4)
    }
}

/// Runs a random distraction, shows a 3-option check-in, and either finishes
/// or loops into another one. "Still having the urge" never routes back to
/// Home. Ported from `renderDistractionRunner`.
struct DistractionLoopView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    let intensity: Int?

    @State private var kind: DistractionKind = DistractionPicker.pickRandom()
    @State private var startedAt = Date()
    @State private var showOutcome = false
    @State private var showFinishChoice: String?
    @State private var noteText = ""
    @State private var showNoteField = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Focus").font(Theme.displayFont(16)).foregroundColor(Theme.text0)
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark").foregroundColor(Theme.text2) }
            }.padding()

            Spacer()
            if let outcome = showFinishChoice {
                finishChoiceView(outcome)
            } else if showOutcome {
                outcomeView
            } else {
                DistractionRunnerDispatch(kind: kind) { showOutcome = true }
            }
            Spacer()
        }
        .background(Theme.bg0.ignoresSafeArea())
    }

    private var outcomeView: some View {
        VStack(spacing: 18) {
            PromptText(text: "How are you feeling now?")
            VStack(spacing: 10) {
                outcomeButton("Better", "better")
                outcomeButton("A little better", "a_little_better")
                outcomeButton("Still having the urge", "still_having_urge")
            }.frame(maxWidth: 340)
            if !showNoteField {
                Button("+ Add a note about what almost got you (optional)") { showNoteField = true }
                    .font(Theme.bodyFont(12.5)).foregroundColor(Theme.text2)
            } else {
                TextEditor(text: $noteText).frame(height: 70).cardBackground()
            }
            Button("Reach out to someone instead") { ReachOutHelper.trigger(store: store) }
                .font(Theme.bodyFont(12.5, weight: .semibold)).foregroundColor(Theme.cyan)
        }.padding(.horizontal, Theme.space4)
    }

    private func outcomeButton(_ label: String, _ value: String) -> some View {
        Button {
            let duration = Int(Date().timeIntervalSince(startedAt))
            store.addSession(AppSession(
                activityId: kind.rawValue, category: "urge-distraction", durationSec: duration,
                outcome: value == "still_having_urge" ? "still_need_help" : value,
                fromUrgeMode: true, intensity: intensity, note: noteText.isEmpty ? nil : noteText))
            if value == "still_having_urge" {
                kind = DistractionPicker.pickRandom(); startedAt = Date(); showOutcome = false; noteText = ""; showNoteField = false
            } else {
                showFinishChoice = value
            }
        } label: {
            Text(label).font(Theme.bodyFont(15, weight: .semibold)).foregroundColor(Theme.text0)
                .frame(maxWidth: .infinity).padding(.vertical, 14).cardBackground()
        }
    }

    private func finishChoiceView(_ outcome: String) -> some View {
        VStack(spacing: 18) {
            PromptText(text: outcome == "better" ? "Glad to hear it." : "That\u2019s good — even a little counts.")
            VStack(spacing: 10) {
                Button("Finish") { dismiss() }.buttonStyle(PrimaryButtonStyle())
                Button("Keep going anyway") {
                    kind = DistractionPicker.pickRandom(); startedAt = Date()
                    showOutcome = false; showFinishChoice = nil; noteText = ""; showNoteField = false
                }.buttonStyle(GhostButtonStyle())
            }.frame(maxWidth: 280)
        }.padding(.horizontal, Theme.space4)
    }
}

enum ReachOutHelper {
    static func trigger(store: DataStore) {
        guard let contact = store.reachOutContact, let url = URL(string: "sms:\(contact.identifier)&body=\(contact.message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else { return }
        UIApplication.shared.open(url)
    }
}
