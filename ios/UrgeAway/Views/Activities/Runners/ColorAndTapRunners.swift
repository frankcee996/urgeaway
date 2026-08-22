import SwiftUI

/// Ported from `runColorFocus`: 6 rounds, tap the named color among 4 swatches.
struct ColorFocusRunner: View {
    let onFinish: () -> Void
    private let rounds = 6
    private let palette: [(name: String, color: Color)] = [
        ("Cyan", Theme.cyan), ("Green", Theme.green), ("Amber", Theme.amber),
        ("Coral", Theme.coral), ("Violet", Color(hex: 0xA78BFA)),
    ]
    @State private var round = 0
    @State private var target: (name: String, color: Color) = ("Cyan", Theme.cyan)
    @State private var choices: [(name: String, color: Color)] = []
    @State private var feedback = ""
    @State private var good = true
    @State private var answered = false

    var body: some View {
        VStack(spacing: 20) {
            TimerPill(text: "Round \(round + 1) of \(rounds)")
            (Text("Tap ") + Text(target.name).foregroundColor(target.color))
                .font(Theme.bodyFont(16, weight: .semibold))
                .foregroundColor(Theme.text0)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(choices.indices, id: \.self) { i in
                    Button {
                        choose(choices[i])
                    } label: {
                        RoundedRectangle(cornerRadius: Theme.radiusM).fill(choices[i].color)
                            .frame(width: 110, height: 110)
                    }
                    .disabled(answered)
                }
            }
            FeedbackFlash(text: feedback, good: good)
        }
        .onAppear(perform: nextRound)
    }

    private func nextRound() {
        answered = false; feedback = ""
        target = palette.randomElement()!
        var shuffled = Array(palette.shuffled().prefix(4))
        if !shuffled.contains(where: { $0.name == target.name }) { shuffled[0] = target }
        choices = shuffled.shuffled()
    }

    private func choose(_ c: (name: String, color: Color)) {
        answered = true
        if c.name == target.name { feedback = "Nice"; good = true } else { feedback = "Not quite"; good = false }
        round += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            if round >= rounds { onFinish() } else { nextRound() }
        }
    }
}

/// Ported from `runTapChallenge`: tap 12 fading dots within 20 seconds.
struct TapChallengeRunner: View {
    let onFinish: () -> Void
    private let targetHits = 12
    private let fieldSize: CGFloat = 260
    @State private var hits = 0
    @State private var timeLeft = 20
    @State private var dots: [Dot] = []
    @State private var timer: Timer?
    @State private var spawnTask: DispatchWorkItem?

    struct Dot: Identifiable { let id = UUID(); var x: CGFloat; var y: CGFloat }

    var body: some View {
        VStack(spacing: 16) {
            TimerPill(text: "\(timeLeft)s · \(hits)/\(targetHits) tapped")
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24).fill(Theme.bg0)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.line, lineWidth: 1))
                ForEach(dots) { dot in
                    Circle()
                        .fill(LinearGradient(colors: [Theme.cyan, Theme.green], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 46, height: 46)
                        .position(x: dot.x, y: dot.y)
                        .onTapGesture { tap(dot) }
                }
            }
            .frame(width: fieldSize, height: fieldSize)
        }
        .onAppear(perform: start)
        .onDisappear(perform: stop)
    }

    private func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeLeft -= 1
            if timeLeft <= 0 || hits >= targetHits { finish() }
        }
        spawn()
    }
    private func stop() { timer?.invalidate(); spawnTask?.cancel() }

    private func spawn() {
        guard timeLeft > 0, hits < targetHits else { return }
        let size: CGFloat = 46
        let dot = Dot(x: CGFloat.random(in: size/2...(fieldSize - size/2)),
                      y: CGFloat.random(in: size/2...(fieldSize - size/2)))
        dots.append(dot)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { dots.removeAll { $0.id == dot.id } }
        let work = DispatchWorkItem(block: spawn)
        spawnTask = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65, execute: work)
    }

    private func tap(_ dot: Dot) {
        hits += 1
        dots.removeAll { $0.id == dot.id }
        if hits >= targetHits { finish() }
    }

    private func finish() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: onFinish)
    }
}
