import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject var store: DataStore

    private var stats: (totalSessions: Int, mostUsed: [(String, Int)], mostHelpful: [(String, Int)]) {
        let sessions = store.sessions
        var byActivity: [String: Int] = [:]
        for s in sessions { byActivity[s.activityId, default: 0] += 1 }
        let mostUsed = byActivity.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
        var helpfulCounts: [String: Int] = [:]
        for s in sessions where s.outcome == "better" || s.outcome == "a_little_better" {
            helpfulCounts[s.activityId, default: 0] += 1
        }
        let mostHelpful = helpfulCounts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
        return (sessions.count, Array(mostUsed), Array(mostHelpful))
    }

    var body: some View {
        let rl = store.getResistanceStats()
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress").font(Theme.displayFont(24)).foregroundColor(Theme.text0)
                    Text("No pressure here — just a record of showing up.").font(Theme.bodyFont(13)).foregroundColor(Theme.text2)
                }

                VStack(alignment: .leading, spacing: Theme.space3) {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Level \(rl.level)").font(Theme.displayFont(22)).foregroundColor(Theme.text0)
                            Text(rl.levelName).font(Theme.bodyFont(12.5, weight: .semibold)).foregroundColor(Theme.cyan)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(rl.points)").font(Theme.displayFont(18)).foregroundColor(Theme.text0)
                            Text("points").font(Theme.bodyFont(11.5)).foregroundColor(Theme.text2)
                        }
                    }
                    if let next = rl.nextLevelName {
                        VStack(alignment: .leading, spacing: 5) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Theme.bg3)
                                    Capsule().fill(LinearGradient(colors: [Theme.cyan, Theme.green], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * rl.progressToNext)
                                }
                            }.frame(height: 7)
                            Text("\(rl.pointsToNext) points to \(next)").font(Theme.bodyFont(11)).foregroundColor(Theme.text2)
                        }
                    } else {
                        Text("Top level reached").font(Theme.bodyFont(11)).foregroundColor(Theme.text2)
                    }
                    HStack(spacing: Theme.space4) {
                        miniStat("\(rl.appOpenDays)", "days shown up")
                        miniStat("\(rl.streakDays)", "day streak")
                        miniStat("\(rl.percentResisted)%", "felt better after")
                    }.padding(.top, Theme.space3)
                        .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .top)
                }.padding(Theme.space3).cardBackground()

                Text("Grows slowly and steadily — showing up, your streak, and how your urge sessions go all count.")
                    .font(Theme.bodyFont(10.5)).foregroundColor(Theme.text2)

                HStack(alignment: .top, spacing: Theme.space3) {
                    listCard(title: "Most used", pairs: stats.mostUsed, emptyText: "Nothing yet.")
                    listCard(title: "You said helped", pairs: stats.mostHelpful, emptyText: "Rate activities to see this.")
                }
            }.padding(Theme.space4)
        }.background(Theme.bg1.ignoresSafeArea())
    }

    private func miniStat(_ num: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(num).font(Theme.displayFont(15)).foregroundColor(Theme.text0)
            Text(label).font(Theme.bodyFont(10.5)).foregroundColor(Theme.text2)
        }
    }

    private func listCard(title: String, pairs: [(String, Int)], emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(Theme.bodyFont(12, weight: .semibold)).foregroundColor(Theme.text2)
            if pairs.isEmpty {
                Text(emptyText).font(Theme.bodyFont(11)).foregroundColor(Theme.text2)
            } else {
                VStack(spacing: 0) {
                    ForEach(pairs, id: \.0) { id, count in
                        HStack {
                            Text(friendlyLabel(id)).font(Theme.bodyFont(11.5, weight: .semibold)).foregroundColor(Theme.text0).lineLimit(1)
                            Spacer()
                            Text("\(count)×").font(Theme.bodyFont(11)).foregroundColor(Theme.text2)
                        }.padding(.vertical, 7)
                        if id != pairs.last?.0 { Divider().background(Theme.line) }
                    }
                }
            }
        }.padding(Theme.space3).cardBackground().frame(maxWidth: .infinity, alignment: .leading)
    }

    private func friendlyLabel(_ id: String) -> String {
        if let a = activity(byId: id) { return a.name }
        if let kind = DistractionKind(rawValue: id) {
            switch kind {
            case .halt: return "HALT Check"
            case .urgeSurf: return "Urge Surfing"
            case .waitItOut: return "Wait It Out"
            case .quickMath: return "Quick Math"
            case .tapWhenGreen: return "Tap When Green"
            case .dontTap: return "Don't Tap"
            case .fastestFinger: return "Fastest Finger"
            case .oddOneOut: return "Odd One Out"
            }
        }
        if id == "urge-lock" { return "Urge Lock" }
        return id
    }
}
