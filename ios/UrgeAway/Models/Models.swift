import Foundation

/// One completed activity/distraction/Urge Lock run.
/// Mirrors the `session` object shape from `Data.addSession` in storage.js.
struct AppSession: Codable, Identifiable, Equatable {
    var id: String
    var activityId: String
    var category: String // "distract" | "challenge" | "calm" | "urge-distraction" | "urge-lock"
    var date: Date
    var durationSec: Int
    var outcome: String // "better" | "a_little_better" | "same" | "still_need_help"
    var fromUrgeMode: Bool
    var intensity: Int?
    var note: String?

    init(activityId: String, category: String, durationSec: Int, outcome: String,
         fromUrgeMode: Bool, intensity: Int? = nil, note: String? = nil) {
        self.id = "sess_\(Int(Date().timeIntervalSince1970 * 1000))_\(Int.random(in: 0..<1000))"
        self.activityId = activityId
        self.category = category
        self.date = Date()
        self.durationSec = durationSec
        self.outcome = outcome
        self.fromUrgeMode = fromUrgeMode
        self.intensity = intensity
        self.note = note
    }
}

/// A private journal entry. Mirrors `Data.addJournalEntry`.
struct JournalEntry: Codable, Identifiable, Equatable {
    var id: String
    var date: Date
    var prompt: String
    var text: String

    init(prompt: String, text: String) {
        self.id = "jrnl_\(Int(Date().timeIntervalSince1970 * 1000))"
        self.date = Date()
        self.prompt = prompt
        self.text = text
    }
}

struct Streak: Codable, Equatable {
    var count: Int = 0
    var lastDate: String? = nil
}

struct AppOpens: Codable, Equatable {
    var totalDays: Int = 0
    var lastDate: String? = nil
}

/// A person-set reminder for a time an urge tends to hit.
/// Mirrors the reminder shape in storage.js; backed by a local notification + `alarm`-style trigger.
struct Reminder: Codable, Identifiable, Equatable {
    var id: String
    var hour: Int
    var minute: Int
    var message: String
    var repeatDaily: Bool
    var enabled: Bool
    var createdAt: Date

    init(hour: Int, minute: Int, message: String, repeatDaily: Bool) {
        self.id = "rem_\(Int(Date().timeIntervalSince1970 * 1000))"
        self.hour = hour
        self.minute = minute
        self.message = message
        self.repeatDaily = repeatDaily
        self.enabled = true
        self.createdAt = Date()
    }
}

struct ReachOutContact: Codable, Equatable {
    var platform: String // "message" | "call" | "whatsapp" etc.
    var identifier: String // phone number / handle
    var message: String
}

struct AppSettings: Codable, Equatable {
    var notificationsEnabled: Bool = false
    var haptics: Bool = true
    var pushEnabled: Bool = false
    var theme: String = "system" // "system" | "light" | "dark"
}

struct NotifHistoryItem: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var body: String
    var ts: Date
}

/// The current/most recent Urge Lock session. Timestamp-based, exactly like
/// the web version, so it survives the app being suspended and relaunched.
struct UrgeLockSession: Codable, Equatable {
    var id: String
    var intensity: Int
    var durationSec: Int
    var startTime: Date
    var endTime: Date
    var status: String // "active" | "completed"
    var feeling: String?

    init(intensity: Int, durationSec: Int) {
        let now = Date()
        self.id = "ulock_\(Int(now.timeIntervalSince1970 * 1000))"
        self.intensity = intensity
        self.durationSec = durationSec
        self.startTime = now
        self.endTime = now.addingTimeInterval(TimeInterval(durationSec))
        self.status = "active"
        self.feeling = nil
    }
}

enum Category: String, CaseIterable {
    case distract, challenge, calm

    var label: String {
        switch self {
        case .distract: return "Distract"
        case .challenge: return "Challenge"
        case .calm: return "Calm"
        }
    }
}

struct ResistanceTier {
    let level: Int
    let min: Int
    let name: String
}

let resistanceTiers: [ResistanceTier] = [
    .init(level: 1, min: 0, name: "Getting Started"),
    .init(level: 2, min: 15, name: "Building Resistance"),
    .init(level: 3, min: 40, name: "Steady"),
    .init(level: 4, min: 80, name: "Resilient"),
    .init(level: 5, min: 140, name: "Strong"),
    .init(level: 6, min: 220, name: "Unshakeable"),
]

struct ResistanceStats {
    var points: Int
    var level: Int
    var levelName: String
    var nextLevelName: String?
    var pointsToNext: Int
    var progressToNext: Double
    var percentResisted: Int
    var totalUrgeSessions: Int
    var appOpenDays: Int
    var streakDays: Int
}

/// Urge Lock duration mapping — intensity determines duration, never a
/// manual choice. 1-6 don't map to anything (no lock offered).
let urgeLockDurationsSec: [Int: Int] = [7: 300, 8: 480, 9: 720, 10: 900]
