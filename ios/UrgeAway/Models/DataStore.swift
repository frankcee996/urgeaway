import Foundation
import Combine

/// Thin wrapper around UserDefaults — the iOS equivalent of SharedPreferences
/// used for `Storage` in storage.js. Everything UrgeAway knows about a person
/// lives only on their device: nothing here ever leaves via network, and
/// there is no networking code at all in this layer.
///
/// Ported 1:1 from `www/js/storage.js` (`Storage` + `Data`). Every public
/// method here corresponds to a same-named function there.
final class DataStore: ObservableObject {
    static let shared = DataStore()

    private let defaults = UserDefaults.standard
    private let prefix = "urgeaway:"

    // Published so SwiftUI views (Progress/Home/Journal) update live —
    // there is no direct localStorage-change-event equivalent, so views
    // read through these published caches instead of calling defaults
    // directly on every render.
    @Published private(set) var sessions: [AppSession] = []
    @Published private(set) var journal: [JournalEntry] = []
    @Published private(set) var streak = Streak()
    @Published private(set) var appOpens = AppOpens()
    @Published private(set) var reminders: [Reminder] = []
    @Published private(set) var reasons: [String] = []
    @Published private(set) var settings = AppSettings()
    @Published private(set) var reachOutContact: ReachOutContact?
    @Published private(set) var streakProtecting: String = ""
    @Published private(set) var profileName: String = ""
    @Published private(set) var notifHistory: [NotifHistoryItem] = []
    @Published private(set) var notifLastViewed: Date = .distantPast
    @Published private(set) var urgeLockSession: UrgeLockSession?
    @Published private(set) var onboarded: Bool = false
    @Published private(set) var loginPromptShown: Bool = false
    @Published private(set) var urgeLockSetupDone: Bool = false

    private init() { reload() }

    // MARK: - Generic get/set (mirrors Storage.get/set)

    private func get<T: Codable>(_ key: String, _ fallback: T) -> T {
        guard let data = defaults.data(forKey: prefix + key) else { return fallback }
        return (try? JSONDecoder.iso.decode(T.self, from: data)) ?? fallback
    }
    private func set<T: Codable>(_ key: String, _ value: T) {
        if let data = try? JSONEncoder.iso.encode(value) {
            defaults.set(data, forKey: prefix + key)
        }
    }
    private func remove(_ key: String) { defaults.removeObject(forKey: prefix + key) }

    /// Reloads every published cache from disk. Call after any write from a
    /// background/async context (e.g. after Firebase auth callbacks).
    func reload() {
        sessions = get(Keys.sessions, [])
        journal = get(Keys.journal, [])
        streak = get(Keys.streak, Streak())
        appOpens = get(Keys.appOpens, AppOpens())
        reminders = get(Keys.reminders, []).sorted { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }
        reasons = get(Keys.reasons, [])
        settings = get(Keys.settings, AppSettings())
        reachOutContact = get(Keys.reachOut, ReachOutContact?.none)
        streakProtecting = get(Keys.streakProtecting, "")
        profileName = get(Keys.profileName, "")
        notifHistory = get(Keys.notifHistory, [])
        notifLastViewed = get(Keys.notifLastViewed, Date.distantPast)
        urgeLockSession = get(Keys.urgeLockSession, UrgeLockSession?.none)
        onboarded = get(Keys.onboarded, false)
        loginPromptShown = get(Keys.loginPromptShown, false)
        urgeLockSetupDone = get(Keys.urgeLockSetupDone, false)
    }

    private enum Keys {
        static let onboarded = "onboarded"
        static let settings = "settings"
        static let sessions = "sessions"
        static let journal = "journal"
        static let streak = "streak"
        static let preferredActivities = "preferred_activities"
        static let reminders = "custom_reminders"
        static let reachOut = "reach_out_contact"
        static let reasons = "my_reasons"
        static let streakProtecting = "streak_protecting"
        static let loginPromptShown = "login_prompt_shown"
        static let notifPermissionAsked = "notif_permission_asked"
        static let notifBannerShown = "notif_banner_shown"
        static let appOpens = "app_opens"
        static let urgeLockSession = "urge_lock_session"
        static let urgeLockSetupDone = "urge_lock_setup_done"
        static let profileName = "profile_name"
        static let notifHistory = "notif_history"
        static let notifLastViewed = "notif_last_viewed"
    }

    // MARK: - Onboarding / login gate

    func isOnboarded() -> Bool { onboarded }
    func setOnboarded(preferredActivities: [String]? = nil) {
        set(Keys.onboarded, true); onboarded = true
        if let p = preferredActivities { set(Keys.preferredActivities, p) }
    }
    func isLoginPromptShown() -> Bool { loginPromptShown }
    func setLoginPromptShown() { set(Keys.loginPromptShown, true); loginPromptShown = true }

    // MARK: - Settings

    func setSettings(_ patch: (inout AppSettings) -> Void) {
        var merged = settings
        patch(&merged)
        set(Keys.settings, merged)
        settings = merged
    }

    // MARK: - Sessions / streak

    private func todayStr(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month!)-\(c.day!)"
    }

    @discardableResult
    func addSession(_ session: AppSession) -> AppSession {
        var list = sessions
        list.append(session)
        set(Keys.sessions, list)
        sessions = list
        updateStreak()
        return session
    }

    func getTodaySessions() -> [AppSession] {
        let today = todayStr()
        return sessions.filter { todayStr($0.date) == today }
    }
    func getUrgeSessionsToday() -> [AppSession] { getTodaySessions().filter(\.fromUrgeMode) }

    @discardableResult
    private func updateStreak() -> Streak {
        var s = streak
        let today = todayStr()
        if s.lastDate == today { return s }
        let yesterday = todayStr(Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        s.count = (s.lastDate == yesterday) ? s.count + 1 : 1
        s.lastDate = today
        set(Keys.streak, s)
        streak = s
        return s
    }

    /// Distinct days the app was opened at all — "showing up" counts toward
    /// Resistance Level even on days with no logged session.
    @discardableResult
    func recordAppOpen() -> AppOpens {
        var rec = appOpens
        let today = todayStr()
        if rec.lastDate == today { return rec }
        rec.totalDays += 1
        rec.lastDate = today
        set(Keys.appOpens, rec)
        appOpens = rec
        return rec
    }

    // MARK: - Journal

    func addJournalEntry(prompt: String, text: String) {
        var list = journal
        list.append(JournalEntry(prompt: prompt, text: text))
        set(Keys.journal, list)
        journal = list.sorted { $0.date > $1.date }
    }
    func deleteJournalEntry(id: String) {
        let list = journal.filter { $0.id != id }
        set(Keys.journal, list)
        journal = list
    }

    // MARK: - Reach out / reasons / streak-protecting

    func setReachOutContact(_ c: ReachOutContact?) { set(Keys.reachOut, c); reachOutContact = c }

    func addReason(_ text: String) {
        var list = reasons; list.append(text); set(Keys.reasons, list); reasons = list
    }
    func deleteReason(at index: Int) {
        var list = reasons; guard list.indices.contains(index) else { return }
        list.remove(at: index); set(Keys.reasons, list); reasons = list
    }

    func setStreakProtecting(_ text: String) { set(Keys.streakProtecting, text); streakProtecting = text }

    // MARK: - Reminders

    @discardableResult
    func addReminder(_ r: Reminder) -> Reminder {
        var list = reminders; list.append(r)
        set(Keys.reminders, list)
        reminders = list.sorted { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }
        return r
    }
    func updateReminder(id: String, patch: (inout Reminder) -> Void) {
        var list = reminders
        guard let idx = list.firstIndex(where: { $0.id == id }) else { return }
        patch(&list[idx])
        set(Keys.reminders, list)
        reminders = list.sorted { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }
    }
    func deleteReminder(id: String) {
        let list = reminders.filter { $0.id != id }
        set(Keys.reminders, list)
        reminders = list
    }

    // MARK: - Profile (local-only)

    func setProfileName(_ name: String) {
        let trimmed = String(name.prefix(40)).trimmingCharacters(in: .whitespacesAndNewlines)
        set(Keys.profileName, trimmed); profileName = trimmed
    }

    // MARK: - Notification history (local-only, capped at 10)

    private let notifHistoryMax = 10
    func addNotifToHistory(id: String? = nil, title: String, body: String) {
        var list = notifHistory
        let itemId = id ?? "notif_\(Int(Date().timeIntervalSince1970 * 1000))_\(Int.random(in: 0..<1000))"
        if list.contains(where: { $0.id == itemId }) { return }
        var next = [NotifHistoryItem(id: itemId, title: title, body: body, ts: Date())]
        next.append(contentsOf: list)
        if next.count > notifHistoryMax { next = Array(next.prefix(notifHistoryMax)) }
        set(Keys.notifHistory, next)
        notifHistory = next
    }
    func markNotifViewed() { set(Keys.notifLastViewed, Date()); notifLastViewed = Date() }
    func getUnreadNotifCount() -> Int { notifHistory.filter { $0.ts > notifLastViewed }.count }

    // MARK: - Simple personalization

    /// Which activity has the best "helpful" ratio, used >= 2 times.
    func getRecommendedActivity() -> ActivityDefinition? {
        var byActivity: [String: (total: Int, helpful: Int)] = [:]
        for s in sessions {
            var e = byActivity[s.activityId] ?? (0, 0)
            e.total += 1
            if s.outcome == "better" || s.outcome == "a_little_better" { e.helpful += 1 }
            byActivity[s.activityId] = e
        }
        var best: String?; var bestScore = 0.0
        for (id, stat) in byActivity {
            guard stat.total >= 2 else { continue }
            let score = Double(stat.helpful) / Double(stat.total)
            if score > bestScore { bestScore = score; best = id }
        }
        guard let bestId = best else { return nil }
        return activityRegistry.first { $0.id == bestId }
    }

    // MARK: - Resistance Level
    // Built from three things so it climbs slowly and steadily just from
    // staying engaged, not only from logging urge sessions: distinct days
    // opened (showing up), current day streak (consistency), and how logged
    // urge sessions went (a smaller bonus on top). Ported from
    // `Data.getResistanceStats` verbatim.
    func getResistanceStats() -> ResistanceStats {
        let urgeSessions = sessions.filter(\.fromUrgeMode)
        var outcomePoints = 0, resistedCount = 0
        for s in urgeSessions {
            if s.outcome == "better" { outcomePoints += 3; resistedCount += 1 }
            else if s.outcome == "a_little_better" { outcomePoints += 2; resistedCount += 1 }
            else if s.outcome == "still_need_help" { outcomePoints += 1 }
            if let i = s.intensity, i >= 7, s.outcome == "better" || s.outcome == "a_little_better" {
                outcomePoints += 1
            }
        }
        let points = appOpens.totalDays + streak.count + outcomePoints
        var current = resistanceTiers[0]
        var next: ResistanceTier? = resistanceTiers.count > 1 ? resistanceTiers[1] : nil
        for (i, tier) in resistanceTiers.enumerated() where points >= tier.min {
            current = tier
            next = i + 1 < resistanceTiers.count ? resistanceTiers[i + 1] : nil
        }
        let progressToNext: Double = next.map { min(1, Double(points - current.min) / Double($0.min - current.min)) } ?? 1
        let percentResisted = urgeSessions.isEmpty ? 0 : Int((Double(resistedCount) / Double(urgeSessions.count) * 100).rounded())
        return ResistanceStats(
            points: points, level: current.level, levelName: current.name,
            nextLevelName: next?.name, pointsToNext: next.map { $0.min - points } ?? 0,
            progressToNext: progressToNext, percentResisted: percentResisted,
            totalUrgeSessions: urgeSessions.count, appOpenDays: appOpens.totalDays, streakDays: streak.count
        )
    }

    // MARK: - Urge Lock (timestamp-based — survives app suspension/relaunch,
    // exactly as in the web version, since it always recomputes
    // `endTime - now` instead of tracking an in-memory countdown.)

    func getUrgeLockDurationSec(intensity: Int) -> Int? { urgeLockDurationsSec[intensity] }

    @discardableResult
    func startUrgeLockSession(intensity: Int) -> UrgeLockSession? {
        guard let duration = getUrgeLockDurationSec(intensity: intensity) else { return nil }
        let session = UrgeLockSession(intensity: intensity, durationSec: duration)
        set(Keys.urgeLockSession, session)
        urgeLockSession = session
        return session
    }
    func completeUrgeLockSession(feeling: String?) {
        guard var s = urgeLockSession else { return }
        s.status = "completed"; s.feeling = feeling
        set(Keys.urgeLockSession, s)
        urgeLockSession = s
    }
    func clearUrgeLockSession() { remove(Keys.urgeLockSession); urgeLockSession = nil }
    func setUrgeLockSetupDone() { set(Keys.urgeLockSetupDone, true); urgeLockSetupDone = true }

    // MARK: - Export / clear (Settings > Privacy & Data)

    struct Export: Codable {
        var exportedAt: Date
        var sessions: [AppSession]
        var journal: [JournalEntry]
        var streak: Streak
        var settings: AppSettings
    }
    func exportAll() -> Export {
        Export(exportedAt: Date(), sessions: sessions, journal: journal, streak: streak, settings: settings)
    }
    func clearAllData() {
        for key in [Keys.onboarded, Keys.settings, Keys.sessions, Keys.journal, Keys.streak,
                    Keys.preferredActivities, Keys.reminders, Keys.reachOut, Keys.reasons,
                    Keys.streakProtecting, Keys.loginPromptShown, Keys.notifPermissionAsked,
                    Keys.notifBannerShown, Keys.appOpens, Keys.urgeLockSession, Keys.urgeLockSetupDone,
                    Keys.profileName, Keys.notifHistory, Keys.notifLastViewed] {
            remove(key)
        }
        reload()
    }
}

extension JSONDecoder {
    static let iso: JSONDecoder = { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d }()
}
extension JSONEncoder {
    static let iso: JSONEncoder = { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e }()
}
