import SwiftUI

/// Ported from `runReactionTest` in activities.js: 3 rounds, tap the circle
/// only once it turns green, too-soon taps reset the round.
struct ReactionTestRunner: View {
    let onFinish: () -> Void
    private let rounds = 3
    @State private var round = 0
    @State private var isGreen = false
    @State private var startedAt: Date?
    @State private var feedback = ""
    @State private var good = true
    @State private var task: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 20) {
            TimerPill(text: "Round \(min(round + 1, rounds)) of \(rounds)")
            PromptText(text: "Wait for the circle to turn green, then tap it.")
            Button(action: onTap) {
                Circle()
                    .fill(isGreen
                          ? AnyShapeStyle(LinearGradient(colors: [Theme.cyan, Theme.green], startPoint: .topLeading, endPoint: .bottomTrailing))
                          : AnyShapeStyle(Theme.bg3))
                    .frame(width: 180, height: 180)
            }
            FeedbackFlash(text: feedback, good: good)
        }
        .onAppear(perform: scheduleRound)
        .onDisappear { task?.cancel() }
    }

    private func scheduleRound() {
        isGreen = false; feedback = ""; startedAt = nil
        let delay = Double.random(in: 1.2...3.4)
        let work = DispatchWorkItem { isGreen = true; startedAt = Date() }
        task = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func onTap() {
        guard let started = startedAt else {
            feedback = "Too soon — wait for green"; good = false
            task?.cancel()
            scheduleRound()
            return
        }
        let ms = Int(Date().timeIntervalSince(started) * 1000)
        feedback = "\(ms)ms"; good = true
        startedAt = nil
        round += 1
        if round >= rounds {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: onFinish)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: scheduleRound)
        }
    }
}

/// Ported from `runMemoryMatch`: 6 symbol pairs on a 4-column grid.
struct MemoryMatchRunner: View {
    let onFinish: () -> Void
    private let symbols = ["◆", "●", "▲", "■", "★", "✚"]
    @State private var cards: [Card] = []
    @State private var firstIndex: Int?
    @State private var locked = false
    @State private var matches = 0

    struct Card: Identifiable { let id = UUID(); let symbol: String; var flipped = false; var matched = false }

    var body: some View {
        VStack(spacing: 16) {
            TimerPill(text: "\(matches) of \(symbols.count) matched")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(cards.indices, id: \.self) { i in
                    Button {
                        onCardTap(i)
                    } label: {
                        Text(cards[i].flipped || cards[i].matched ? cards[i].symbol : "")
                            .font(.system(size: 26))
                            .foregroundColor(Theme.cyan)
                            .frame(width: 64, height: 64)
                            .background(cards[i].matched ? Theme.green.opacity(0.18) : (cards[i].flipped ? Theme.bg3 : Theme.bg2))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                            .overlay(RoundedRectangle(cornerRadius: Theme.radiusS).stroke(cards[i].matched ? Theme.green.opacity(0.5) : Theme.line, lineWidth: 1))
                    }
                    .disabled(cards[i].matched || locked)
                }
            }
            .frame(maxWidth: 300)
        }
        .onAppear {
            cards = (symbols + symbols).shuffled().map { Card(symbol: $0) }
        }
    }

    private func onCardTap(_ i: Int) {
        guard !locked, !cards[i].flipped, !cards[i].matched else { return }
        cards[i].flipped = true
        guard let first = firstIndex else { firstIndex = i; return }
        locked = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            if cards[first].symbol == cards[i].symbol {
                cards[first].matched = true; cards[i].matched = true
                matches += 1
            } else {
                cards[first].flipped = false; cards[i].flipped = false
            }
            firstIndex = nil; locked = false
            if matches == symbols.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: onFinish)
            }
        }
    }
}
