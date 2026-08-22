import SwiftUI

/// Maps an `ActivityDefinition.id` to its SwiftUI runner — the native
/// equivalent of `activity.run(container, onFinish)` in activities.js.
struct ActivityRunnerDispatch: View {
    let activityId: String
    let onFinish: () -> Void

    var body: some View {
        switch activityId {
        case "memory_match": MemoryMatchRunner(onFinish: onFinish)
        case "color_focus": ColorFocusRunner(onFinish: onFinish)
        case "tap_challenge": TapChallengeRunner(onFinish: onFinish)
        case "reaction_test": ReactionTestRunner(onFinish: onFinish)
        case "number_challenge": NumberChallengeRunner(onFinish: onFinish)
        case "pattern_challenge": PatternChallengeRunner(onFinish: onFinish)
        case "breathing": BreathingRunner(onFinish: onFinish)
        case "grounding_54321": Grounding54321Runner(onFinish: onFinish)
        case "focus_reset": FocusResetRunner(onFinish: onFinish)
        default: BreathingRunner(onFinish: onFinish)
        }
    }
}
