import SwiftUI

/// One entry in the Activities tab. Ported from the `ACTIVITIES` registry in
/// `activities.js` — adding a new activity later means adding one entry here
/// plus a matching SwiftUI runner view, same "one object per activity"
/// pattern the web version documents for its own registry.
struct ActivityDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let category: String // "distract" | "challenge" | "calm"
    let minutes: String
    let systemIcon: String

    static func == (l: ActivityDefinition, r: ActivityDefinition) -> Bool { l.id == r.id }
}

let activityRegistry: [ActivityDefinition] = [
    .init(id: "memory_match", name: "Memory Match", category: "distract", minutes: "2-3 min", systemIcon: "square.grid.2x2"),
    .init(id: "color_focus", name: "Color Focus", category: "distract", minutes: "1-2 min", systemIcon: "paintpalette"),
    .init(id: "tap_challenge", name: "Tap Challenge", category: "distract", minutes: "~20 sec", systemIcon: "hand.tap"),
    .init(id: "reaction_test", name: "Reaction Test", category: "challenge", minutes: "1 min", systemIcon: "bolt"),
    .init(id: "number_challenge", name: "Number Challenge", category: "challenge", minutes: "1-2 min", systemIcon: "number"),
    .init(id: "pattern_challenge", name: "Pattern Challenge", category: "challenge", minutes: "1-2 min", systemIcon: "triangle"),
    .init(id: "breathing", name: "Breathing", category: "calm", minutes: "~1 min", systemIcon: "wind"),
    .init(id: "grounding_54321", name: "5-4-3-2-1 Grounding", category: "calm", minutes: "2-3 min", systemIcon: "leaf"),
    .init(id: "focus_reset", name: "Focus Reset", category: "calm", minutes: "~1 min", systemIcon: "arrow.clockwise"),
]

func activity(byId id: String) -> ActivityDefinition? { activityRegistry.first { $0.id == id } }
func activities(inCategory category: String) -> [ActivityDefinition] { activityRegistry.filter { $0.category == category } }
func randomActivity(excluding category: String? = nil) -> ActivityDefinition {
    let pool = category.map { c in activityRegistry.filter { $0.category != c } } ?? activityRegistry
    return pool.randomElement() ?? activityRegistry[0]
}
