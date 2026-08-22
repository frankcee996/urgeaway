import SwiftUI

/// Ported from `runBreathing`: 4 cycles of in(4)/hold(4)/out(4)/hold(4) with
/// a scaling breathing circle.
struct BreathingRunner: View {
    let onFinish: () -> Void
    private struct Phase { let label: String; let seconds: Double; let scale: CGFloat }
    private let phases = [
        Phase(label: "Breathe in", seconds: 4, scale: 1.5),
        Phase(label: "Hold", seconds: 4, scale: 1.5),
        Phase(label: "Breathe out", seconds: 4, scale: 1.0),
        Phase(label: "Hold", seconds: 4, scale: 1.0),
    ]
    @State private var phaseIndex = 0
    @State private var cyclesLeft = 4
    @State private var scale: CGFloat = 1.0
    @State private var label = "Breathe in"
    @State private var task: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 24) {
            TimerPill(text: "\(cyclesLeft) cycles left")
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Theme.green, Theme.cyan], center: .center, startRadius: 0, endRadius: 90))
                    .frame(width: 120, height: 120)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 4), value: scale)
                Text(label)
                    .font(Theme.bodyFont(14, weight: .semibold))
                    .foregroundColor(Theme.bg0)
            }
            .frame(height: 200)
            Text("Let your shoulders drop. There's nowhere else to be.")
                .font(Theme.bodyFont(13))
                .foregroundColor(Theme.text2)
        }
        .onAppear(perform: runPhase)
        .onDisappear { task?.cancel() }
    }

    private func runPhase() {
        let phase = phases[phaseIndex]
        label = phase.label
        scale = phase.scale
        let work = DispatchWorkItem {
            phaseIndex += 1
            if phaseIndex >= phases.count {
                phaseIndex = 0
                cyclesLeft -= 1
                if cyclesLeft <= 0 { onFinish(); return }
            }
            runPhase()
        }
        task = work
        DispatchQueue.main.asyncAfter(deadline: .now() + phase.seconds, execute: work)
    }
}

/// Ported from `runGrounding54321`: the 5-4-3-2-1 sensory grounding technique.
struct Grounding54321Runner: View {
    let onFinish: () -> Void
    private let steps: [(n: Int, sense: String)] = [
        (5, "things you can see"), (4, "things you can feel"), (3, "things you can hear"),
        (2, "things you can smell"), (1, "thing you like about yourself"),
    ]
    @State private var i = 0

    var body: some View {
        let step = steps[i]
        VStack(spacing: 22) {
            TimerPill(text: "Step \(i + 1) of \(steps.count)")
            Text("\(step.n)").font(Theme.displayFont(56)).foregroundColor(Theme.cyan)
            PromptText(text: "Notice \(step.n) \(step.sense).")
            Text("Take your time. Tap next when ready.")
                .font(Theme.bodyFont(13)).foregroundColor(Theme.text2)
            Button(i == steps.count - 1 ? "Finish" : "Next") {
                i += 1
                if i >= steps.count { onFinish() }
            }
            .buttonStyle(PrimaryButtonStyle(fullWidth: false))
            .frame(maxWidth: 220)
        }
    }
}

/// Ported from `runFocusReset`: 4 steps of 15s guided noticing.
struct FocusResetRunner: View {
    let onFinish: () -> Void
    private let steps: [(title: String, body: String)] = [
        ("Notice the sounds around you", "Don\u2019t label them. Just notice they\u2019re there."),
        ("Notice where your body meets the chair or floor", "Feel the weight and the support beneath you."),
        ("Notice your breath, without changing it", "Just watch it move in and out."),
        ("Notice one thing you can see nearby", "Look at its color, shape, texture."),
    ]
    @State private var i = 0
    @State private var remaining = 15
    @State private var timer: Timer?

    var body: some View {
        let step = steps[i]
        VStack(spacing: 18) {
            TimerPill(text: "\(max(remaining, 0))s")
            PromptText(text: step.title)
            Text(step.body).font(Theme.bodyFont(13.5)).foregroundColor(Theme.text2)
                .multilineTextAlignment(.center).frame(maxWidth: 280)
        }
        .onAppear(perform: startStep)
        .onDisappear { timer?.invalidate() }
    }

    private func startStep() {
        remaining = 15
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            remaining -= 1
            if remaining <= 0 {
                timer?.invalidate()
                i += 1
                if i >= steps.count { onFinish() } else { startStep() }
            }
        }
    }
}
