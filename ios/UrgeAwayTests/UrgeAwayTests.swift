import XCTest
@testable import UrgeAway

final class ModelsTests: XCTestCase {

    func testActivityRegistryHasNineActivitiesAcrossThreeCategories() {
        XCTAssertEqual(activityRegistry.count, 9)
        XCTAssertEqual(activities(inCategory: "distract").count, 3)
        XCTAssertEqual(activities(inCategory: "challenge").count, 3)
        XCTAssertEqual(activities(inCategory: "calm").count, 3)
    }

    func testActivityLookupById() {
        XCTAssertEqual(activity(byId: "breathing")?.name, "Breathing")
        XCTAssertNil(activity(byId: "does_not_exist"))
    }

    func testUrgeLockDurationMapping() {
        XCTAssertEqual(urgeLockDurationsSec[7], 300)
        XCTAssertEqual(urgeLockDurationsSec[8], 480)
        XCTAssertEqual(urgeLockDurationsSec[9], 720)
        XCTAssertEqual(urgeLockDurationsSec[10], 900)
        XCTAssertNil(urgeLockDurationsSec[6])
    }

    func testResistanceTiersAreOrderedByMinPoints() {
        for i in 1..<resistanceTiers.count {
            XCTAssertGreaterThan(resistanceTiers[i].min, resistanceTiers[i - 1].min)
        }
    }

    func testDistractionPickerAlwaysReturnsAValidKind() {
        for _ in 0..<50 {
            let kind = DistractionPicker.pickRandom()
            XCTAssertTrue(DistractionKind.allCases.contains(kind))
        }
    }
}

final class DataStoreTests: XCTestCase {
    /// Uses the app's real DataStore singleton (backed by UserDefaults.standard)
    /// and clears afterward, since DataStore is not currently DI-friendly.
    /// Good enough to verify the session/journal/reminder logic compiles and
    /// behaves correctly; a follow-up could inject a UserDefaults(suiteName:)
    /// test double for full isolation.
    override func tearDown() {
        DataStore.shared.clearAllData()
        super.tearDown()
    }

    func testAddingASessionUpdatesTodayCount() {
        let store = DataStore.shared
        store.clearAllData()
        XCTAssertEqual(store.getTodaySessions().count, 0)
        store.addSession(AppSession(activityId: "breathing", category: "calm", durationSec: 60, outcome: "better", fromUrgeMode: false))
        XCTAssertEqual(store.getTodaySessions().count, 1)
    }

    func testJournalEntryRoundTrips() {
        let store = DataStore.shared
        store.clearAllData()
        store.addJournalEntry(prompt: "What triggered this moment?", text: "Test entry")
        XCTAssertEqual(store.journal.count, 1)
        XCTAssertEqual(store.journal.first?.text, "Test entry")
    }

    func testReminderAddUpdateDelete() {
        let store = DataStore.shared
        store.clearAllData()
        let r = store.addReminder(Reminder(hour: 9, minute: 30, message: "Check in", repeatDaily: true))
        XCTAssertEqual(store.reminders.count, 1)
        store.updateReminder(id: r.id) { $0.enabled = false }
        XCTAssertEqual(store.reminders.first?.enabled, false)
        store.deleteReminder(id: r.id)
        XCTAssertTrue(store.reminders.isEmpty)
    }
}
