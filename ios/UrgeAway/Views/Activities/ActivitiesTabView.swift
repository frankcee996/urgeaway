import SwiftUI

struct ActivitiesTabView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var router: AppRouter

    private let groups: [(key: String, title: String, desc: String)] = [
        ("distract", "Distract", "Short games to shift your attention"),
        ("challenge", "Challenge", "Simple attention tasks"),
        ("calm", "Calm", "Breathing & grounding"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activities").font(Theme.displayFont(24)).foregroundColor(Theme.text0)
                    Text("Browse anytime — not just during an urge.").font(Theme.bodyFont(13)).foregroundColor(Theme.text2)
                }
                ForEach(groups, id: \.key) { g in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(g.title).font(Theme.bodyFont(12, weight: .semibold)).foregroundColor(Theme.text2)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(activities(inCategory: g.key)) { a in
                                Button { router.launchActivity(a) } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: a.systemIcon).foregroundColor(tint(g.key))
                                            .frame(width: 40, height: 40).background(tint(g.key).opacity(0.14)).clipShape(RoundedRectangle(cornerRadius: 12))
                                        Text(a.name).font(Theme.bodyFont(11.5, weight: .semibold)).foregroundColor(Theme.text0)
                                            .multilineTextAlignment(.center).lineLimit(2)
                                        Text(a.minutes).font(Theme.bodyFont(9.5)).foregroundColor(Theme.text2)
                                    }.frame(maxWidth: .infinity).padding(.vertical, 12).cardBackground()
                                }
                            }
                        }
                    }
                }
                if let rec = store.getRecommendedActivity() {
                    Button { router.launchActivity(rec) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: rec.systemIcon).foregroundColor(tint(rec.category))
                                .frame(width: 32, height: 32).background(tint(rec.category).opacity(0.14)).clipShape(RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(rec.name) seems to help you").font(Theme.bodyFont(13, weight: .bold)).foregroundColor(Theme.text0)
                                Text("Tap to try it now").font(Theme.bodyFont(11)).foregroundColor(Theme.text2)
                            }
                            Spacer()
                        }.padding(Theme.space3).background(Theme.bg2).clipShape(RoundedRectangle(cornerRadius: Theme.radiusM))
                            .overlay(RoundedRectangle(cornerRadius: Theme.radiusM).stroke(Theme.cyan.opacity(0.28), lineWidth: 1))
                    }
                }
            }.padding(Theme.space4)
        }.background(Theme.bg1.ignoresSafeArea())
    }

    private func tint(_ category: String) -> Color {
        switch category {
        case "challenge": return Theme.amber
        case "calm": return Theme.green
        default: return Theme.cyan
        }
    }
}
