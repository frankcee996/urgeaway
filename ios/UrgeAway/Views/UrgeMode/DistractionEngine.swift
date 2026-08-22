import SwiftUI

/// The pool the "I HAVE AN URGE" button draws from during Urge Mode.
/// Ported from `distractions.js`. That file builds ~30 generator types from
/// content banks combined at random; this native port implements the full
/// weighted-random-with-no-immediate-repeat architecture and a faithful,
/// representative set of generator types spanning every interaction pattern
/// used there (guided prompt sequences, HALT-style check-ins, reflex/attention
/// games, quick math). Additional generator *types* can be added the same
/// way the web version documents — one `DistractionType` entry — without
/// touching the picker itself. See the migration report for the full list
/// of web-only generator types not yet ported (they're content variations
/// of these same patterns, not new interaction models).
enum DistractionKind: String, CaseIterable {
    case halt, urgeSurf, waitItOut, quickMath, tapWhenGreen, dontTap, fastestFinger, oddOneOut
}

struct DistractionType {
    let kind: DistractionKind
    let weight: Int
}

let distractionTypes: [DistractionType] = [
    .init(kind: .halt, weight: 2),
    .init(kind: .urgeSurf, weight: 2),
    .init(kind: .waitItOut, weight: 1),
    .init(kind: .quickMath, weight: 2),
    .init(kind: .tapWhenGreen, weight: 2),
    .init(kind: .dontTap, weight: 2),
    .init(kind: .fastestFinger, weight: 2),
    .init(kind: .oddOneOut, weight: 2),
]

enum DistractionPicker {
    private static var recent: [DistractionKind] = []
    private static let weightedPool: [DistractionKind] = distractionTypes.flatMap { Array(repeating: $0.kind, count: $0.weight) }

    static func pickRandom() -> DistractionKind {
        var attempt = weightedPool.randomElement()!
        for _ in 0..<6 {
            let candidate = weightedPool.randomElement()!
            if !recent.contains(candidate) { attempt = candidate; break }
            attempt = candidate
        }
        recent.append(attempt)
        if recent.count > 6 { recent.removeFirst() }
        return attempt
    }
}

/// Dispatches to the right generator view for a picked kind — the native
/// equivalent of `current.run(container, onFinish)`.
struct DistractionRunnerDispatch: View {
    let kind: DistractionKind
    let onFinish: () -> Void
    var body: some View {
        switch kind {
        case .halt: HaltCheckRunner(onFinish: onFinish)
        case .urgeSurf: UrgeSurfingRunner(onFinish: onFinish)
        case .waitItOut: WaitItOutRunner(onFinish: onFinish)
        case .quickMath: QuickMathRunner(onFinish: onFinish)
        case .tapWhenGreen: TapWhenGreenRunner(onFinish: onFinish)
        case .dontTap: DontTapRunner(onFinish: onFinish)
        case .fastestFinger: FastestFingerRunner(onFinish: onFinish)
        case .oddOneOut: OddOneOutRunner(onFinish: onFinish)
        }
    }
}

// MARK: - HALT check — ported from runHaltCheck

private let haltSuggestions: [String: String] = [
    "hungry": "That's worth listening to. A glass of water or a small snack can take the edge off more than you'd expect.",
    "angry": "That's a real feeling, not a flaw. Try unclenching your jaw and dropping your shoulders for a second.",
    "lonely": "Reaching out to one person, even with a short message, tends to help more than waiting it out alone.",
    "tired": "Urges often hit harder when you're running on empty. If you can, this might be a sign to rest soon.",
    "none": "Good to know. Sometimes an urge is just an urge — let's keep going.",
]

struct HaltCheckRunner: View {
    let onFinish: () -> Void
    @State private var picked: String?

    private let options: [(key: String, label: String)] = [
        ("hungry", "Hungry"), ("angry", "Angry / frustrated"), ("lonely", "Lonely"),
        ("tired", "Tired"), ("none", "None of these"),
    ]

    var body: some View {
        VStack(spacing: 20) {
            if let key = picked {
                PromptText(text: haltSuggestions[key] ?? "")
                Button("Continue", action: onFinish).buttonStyle(PrimaryButtonStyle(fullWidth: false)).frame(maxWidth: 220)
            } else {
                PromptText(text: "Quick check — right now, are you...")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(options, id: \.key) { opt in
                        OptionCard(title: opt.label, disabled: false) { picked = opt.key }
                            .gridCellColumns(opt.key == "none" ? 2 : 1)
                    }
                }
                .frame(maxWidth: 300)
            }
        }
    }
}

// MARK: - Urge Surfing — ported from runUrgeSurfing

private let urgeSurfPrompts = [
    "This urge is real, and it's also temporary. Let's just watch it for a minute, without acting on it.",
    "Notice where you feel it in your body. You don't have to change it — just notice it.",
    "Urges rise like a wave. Right now, yours might be rising. That's okay. Waves crest.",
    "You don't have to fight it or obey it. You can just let it be here for a moment.",
    "If you can, picture it peaking soon, then slowly, slowly easing off — the way waves always do.",
    "It's still here, and that's fine. You're not required to do anything about it right this second.",
    "However strong it feels right now, it will not stay this strong. That's just how urges work.",
]

struct UrgeSurfingRunner: View {
    let onFinish: () -> Void
    @State private var i = 0
    var body: some View {
        let isLast = i == urgeSurfPrompts.count - 1
        VStack(spacing: 24) {
            Circle().fill(LinearGradient(colors: [Theme.cyan, Theme.green], startPoint: .top, endPoint: .bottom))
                .frame(width: 90, height: 90)
                .scaleEffect(1 + CGFloat(i) / CGFloat(urgeSurfPrompts.count) * 0.4)
                .animation(.easeInOut(duration: 1.2), value: i)
            PromptText(text: urgeSurfPrompts[i])
            Button(isLast ? "I\u2019m okay" : "Still with it") {
                i += 1
                if i >= urgeSurfPrompts.count { onFinish() }
            }
            .buttonStyle(PrimaryButtonStyle(fullWidth: false)).frame(maxWidth: 220)
        }
    }
}

// MARK: - Wait It Out — ported from runWaitItOut (simplified fixed timer)

private let waitMessages = [
    "Urges are time-limited. They peak, then they fade — even without you doing anything.",
    "You don't have to win this. You just have to outlast the next few minutes.",
    "This feeling is uncomfortable, not dangerous. It will pass.",
    "Every minute that goes by, the intensity tends to drop a little.",
    "You've gotten through hard moments before. This is another one of those.",
    "Nothing bad happens if you just wait. That's the whole plan right now.",
]

struct WaitItOutRunner: View {
    let onFinish: () -> Void
    @State private var remaining = 60
    @State private var message = waitMessages.randomElement()!
    @State private var timer: Timer?
    var body: some View {
        VStack(spacing: 20) {
            TimerPill(text: "\(remaining)s")
            PromptText(text: message)
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                remaining -= 1
                if remaining % 15 == 0 { message = waitMessages.randomElement()! }
                if remaining <= 0 { timer?.invalidate(); onFinish() }
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}

// MARK: - Quick Math — ported from runQuickMath

struct QuickMathRunner: View {
    let onFinish: () -> Void
    @State private var round = 0
    @State private var a = Int.random(in: 2...20)
    @State private var b = Int.random(in: 2...20)
    @State private var answered = false
    @State private var feedback = ""
    @State private var good = true
    private let rounds = 4

    var body: some View {
        VStack(spacing: 20) {
            TimerPill(text: "\(round + 1) of \(rounds)")
            Text("\(a) + \(b)").font(Theme.displayFont(40)).foregroundColor(Theme.text0)
            let correct = a + b
            let options = Set([correct, correct + 1, correct - 2, correct + 3]).sorted()
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(options, id: \.self) { opt in
                    OptionCard(title: "\(opt)", disabled: answered) {
                        answered = true
                        good = opt == correct
                        feedback = good ? "Correct" : "It was \(correct)"
                        round += 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if round >= rounds { onFinish() }
                            else { a = Int.random(in: 2...20); b = Int.random(in: 2...20); answered = false; feedback = "" }
                        }
                    }
                }
            }.frame(maxWidth: 300)
            FeedbackFlash(text: feedback, good: good)
        }
    }
}

// MARK: - Tap When Green — ported from runTapWhenGreen

struct TapWhenGreenRunner: View {
    let onFinish: () -> Void
    private let totalRounds = 5
    @State private var round = 0
    @State private var boxColor = Theme.bg3
    @State private var isGreen = false
    @State private var feedback = ""
    @State private var good = true
    @State private var task: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 18) {
            PromptText(text: "Tap only when it turns green")
            TimerPill(text: "\(min(round + 1, totalRounds)) / \(totalRounds)")
            Button {
                good = isGreen
                feedback = isGreen ? "Nice!" : "Too soon!"
                round += 1
                task?.cancel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: nextRound)
            } label: {
                RoundedRectangle(cornerRadius: Theme.radiusM).fill(boxColor).frame(width: 140, height: 140)
            }
            FeedbackFlash(text: feedback, good: good)
        }
        .onAppear(perform: nextRound)
        .onDisappear { task?.cancel() }
    }

    private func nextRound() {
        guard round < totalRounds else { onFinish(); return }
        boxColor = Theme.bg3; isGreen = false
        let work = DispatchWorkItem {
            isGreen = Double.random(in: 0...1) < 0.6
            boxColor = isGreen ? Color(hex: 0x22C55E) : [Color(hex: 0xEF4444), Color(hex: 0xEAB308)].randomElement()!
        }
        task = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.6...2.0), execute: work)
    }
}

// MARK: - Don't Tap — ported from runDontTap

struct DontTapRunner: View {
    let onFinish: () -> Void
    private let size = 12
    private let unsafeCount = 4
    @State private var unsafeIndices: Set<Int> = []
    @State private var disabled: Set<Int> = []
    @State private var found: Set<Int> = []
    @State private var feedback = ""
    @State private var good = true

    var body: some View {
        VStack(spacing: 16) {
            PromptText(text: "Tap the stars \u{2B50} — avoid the \u{1F4A5}")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(0..<size, id: \.self) { i in
                    Button {
                        tap(i)
                    } label: {
                        Text(unsafeIndices.contains(i) ? "\u{1F4A5}" : "\u{2B50}")
                            .font(.system(size: 24))
                            .frame(width: 60, height: 60)
                            .background(found.contains(i) ? Theme.cyan.opacity(0.3) : (disabled.contains(i) ? Theme.coral.opacity(0.35) : Theme.bg2))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                            .overlay(RoundedRectangle(cornerRadius: Theme.radiusS).stroke(Theme.line, lineWidth: 1))
                    }.disabled(disabled.contains(i))
                }
            }.frame(maxWidth: 280)
            FeedbackFlash(text: feedback, good: good)
        }
        .onAppear {
            var s: Set<Int> = []
            while s.count < unsafeCount { s.insert(Int.random(in: 0..<size)) }
            unsafeIndices = s
        }
    }

    private func tap(_ i: Int) {
        disabled.insert(i)
        if unsafeIndices.contains(i) {
            feedback = "Oops — that one was off-limits."; good = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: onFinish)
        } else {
            found.insert(i)
            if found.count >= size - unsafeCount {
                feedback = "All clear!"; good = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: onFinish)
            }
        }
    }
}

// MARK: - Fastest Finger — ported from runFastestFinger

struct FastestFingerRunner: View {
    let onFinish: () -> Void
    private let totalRounds = 3
    private let fieldW: CGFloat = 280, fieldH: CGFloat = 200
    @State private var round = 0
    @State private var target: CGPoint?
    @State private var appearedAt: Date?
    @State private var feedback = ""
    @State private var task: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 16) {
            PromptText(text: "Tap the target the instant it appears")
            TimerPill(text: "\(min(round + 1, totalRounds)) / \(totalRounds)")
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Theme.radiusM).fill(Theme.bg2)
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusM).stroke(Theme.line, lineWidth: 1))
                if let t = target {
                    Circle().fill(Theme.cyan).frame(width: 52, height: 52)
                        .position(t)
                        .onTapGesture {
                            if let started = appearedAt {
                                feedback = "\(Int(Date().timeIntervalSince(started) * 1000))ms"
                            }
                            target = nil
                            round += 1
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: nextRound)
                        }
                }
            }.frame(width: fieldW, height: fieldH)
            FeedbackFlash(text: feedback, good: true)
        }
        .onAppear(perform: nextRound)
        .onDisappear { task?.cancel() }
    }

    private func nextRound() {
        guard round < totalRounds else { onFinish(); return }
        target = nil; feedback = ""
        let work = DispatchWorkItem {
            target = CGPoint(x: CGFloat.random(in: 26...(fieldW - 26)), y: CGFloat.random(in: 26...(fieldH - 26)))
            appearedAt = Date()
        }
        task = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.7...2.3), execute: work)
    }
}

// MARK: - Odd One Out — ported from runOddOneOut

struct OddOneOutRunner: View {
    let onFinish: () -> Void
    private let emojiSets: [[String]] = [
        ["\u{1F34E}", "\u{1F34E}", "\u{1F34E}", "\u{1F34C}", "\u{1F34E}"],
        ["\u{1F436}", "\u{1F436}", "\u{1F431}", "\u{1F436}", "\u{1F436}"],
        ["\u2B50", "\u2B50", "\u2B50", "\u2B50", "\u{1F319}"],
        ["\u2600\uFE0F", "\u2600\uFE0F", "\u2601\uFE0F", "\u2600\uFE0F", "\u2600\uFE0F"],
    ]
    @State private var round = 0
    @State private var set: [(symbol: String, isOdd: Bool)] = []
    @State private var feedback = ""
    @State private var good = true
    @State private var answered = false
    private let rounds = 4

    var body: some View {
        VStack(spacing: 18) {
            TimerPill(text: "\(round + 1) of \(rounds)")
            PromptText(text: "Which one is different?")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(set.indices, id: \.self) { i in
                    Button {
                        answered = true
                        good = set[i].isOdd
                        feedback = good ? "Correct" : "Not quite"
                        round += 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if round >= rounds { onFinish() } else { nextRound() }
                        }
                    } label: {
                        Text(set[i].symbol).font(.system(size: 30))
                            .frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(Theme.bg2).clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
                            .overlay(RoundedRectangle(cornerRadius: Theme.radiusM).stroke(Theme.line, lineWidth: 1))
                    }.disabled(answered)
                }
            }.frame(maxWidth: 300)
            FeedbackFlash(text: feedback, good: good)
        }
        .onAppear(perform: nextRound)
    }

    private func nextRound() {
        answered = false; feedback = ""
        let base = emojiSets.randomElement()!
        let oddIndex = Int.random(in: 0..<base.count)
        set = base.enumerated().map { (idx, sym) in (symbol: sym, isOdd: idx == oddIndex) }.shuffled()
    }
}
