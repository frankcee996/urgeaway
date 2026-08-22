import SwiftUI

/// Ported from `runNumberChallenge`: 6 quick arithmetic questions, 4 options each.
struct NumberChallengeRunner: View {
    let onFinish: () -> Void
    private let rounds = 6
    @State private var round = 0
    @State private var question = NumberChallengeRunner.makeQuestion()
    @State private var feedback = ""
    @State private var good = true
    @State private var answered = false

    struct Question { let text: String; let answer: Int; let options: [Int] }

    static func makeQuestion() -> Question {
        let ops = ["+", "-", "×"]
        let op = ops.randomElement()!
        let a: Int, b: Int
        if op == "×" { a = Int.random(in: 2...10); b = Int.random(in: 2...10) }
        else { a = Int.random(in: 5...44); b = Int.random(in: 1...20) }
        let answer = op == "+" ? a + b : op == "-" ? a - b : a * b
        var options: Set<Int> = [answer]
        while options.count < 4 {
            let delta = Int.random(in: -5...4)
            options.insert(answer + (delta == 0 ? 3 : delta))
        }
        return Question(text: "\(a) \(op) \(b)", answer: answer, options: Array(options).shuffled())
    }

    var body: some View {
        VStack(spacing: 20) {
            TimerPill(text: "Question \(round + 1) of \(rounds)")
            Text(question.text)
                .font(Theme.displayFont(40, weight: .heavy))
                .foregroundColor(Theme.text0)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(question.options, id: \.self) { opt in
                    OptionCard(title: "\(opt)", disabled: answered) { choose(opt) }
                }
            }
            .frame(maxWidth: 300)
            FeedbackFlash(text: feedback, good: good)
        }
    }

    private func choose(_ opt: Int) {
        answered = true
        if opt == question.answer { feedback = "Correct"; good = true }
        else { feedback = "Answer was \(question.answer)"; good = false }
        round += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            if round >= rounds { onFinish() }
            else { question = Self.makeQuestion(); feedback = ""; answered = false }
        }
    }
}

/// Ported from `runPatternChallenge`: 5 rounds of "what comes next?" sequences.
struct PatternChallengeRunner: View {
    let onFinish: () -> Void
    private let rounds = 5
    @State private var round = 0
    @State private var question = PatternChallengeRunner.makeSequence()
    @State private var feedback = ""
    @State private var good = true
    @State private var answered = false

    struct Question { let seq: [Int]; let answer: Int; let options: [Int] }

    static func makeSequence() -> Question {
        let seq: [Int]; let answer: Int
        if Bool.random() {
            let start = Int.random(in: 1...10), step = Int.random(in: 2...6)
            seq = [start, start + step, start + step * 2, start + step * 3]
            answer = start + step * 4
        } else {
            let a = Int.random(in: 1...9), b = Int.random(in: 1...9)
            seq = [a, b, a, b, a]
            answer = b
        }
        var options: Set<Int> = [answer]
        while options.count < 4 { options.insert(answer + Int.random(in: -4...4)) }
        return Question(seq: seq, answer: answer, options: Array(options).shuffled())
    }

    var body: some View {
        VStack(spacing: 20) {
            TimerPill(text: "Round \(round + 1) of \(rounds)")
            PromptText(text: "What comes next?")
            Text(question.seq.map(String.init).joined(separator: "  ·  ") + "  ·  ?")
                .font(Theme.displayFont(30, weight: .bold))
                .foregroundColor(Theme.text0)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(question.options, id: \.self) { opt in
                    OptionCard(title: "\(opt)", disabled: answered) { choose(opt) }
                }
            }
            .frame(maxWidth: 300)
            FeedbackFlash(text: feedback, good: good)
        }
    }

    private func choose(_ opt: Int) {
        answered = true
        if opt == question.answer { feedback = "Correct"; good = true }
        else { feedback = "It was \(question.answer)"; good = false }
        round += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            if round >= rounds { onFinish() }
            else { question = Self.makeSequence(); feedback = ""; answered = false }
        }
    }
}
