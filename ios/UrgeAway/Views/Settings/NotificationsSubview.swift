import SwiftUI

struct NotificationsSubview: View {
    @EnvironmentObject var store: DataStore
    @State private var busy = false
    @State private var pushStatus = ""
    @State private var showComposer = false
    @State private var toast: String?

    var body: some View {
        SettingsSubviewScaffold(title: "Notifications & Reminders") {
            settingsSectionTitle("Notifications")
            VStack(spacing: 0) {
                toggleRow(title: "Gentle reminders",
                          desc: "One nudge a day, around 10am, plus occasional updates from UrgeAway. Never reveals anything sensitive on your lock screen.",
                          isOn: store.settings.notificationsEnabled, busy: busy) { toggleNotifications() }
                Divider().background(Theme.line)
                toggleRow(title: "Haptic feedback", desc: "Subtle vibration on key actions",
                          isOn: store.settings.haptics, busy: false) {
                    store.setSettings { $0.haptics.toggle() }
                }
            }.cardBackground()
            Text(pushStatusText).font(Theme.bodyFont(11.5)).foregroundColor(Theme.text2)

            settingsSectionTitle("Your reminders")
            Text("Set a reminder for a time an urge tends to hit, with your own message to yourself — like an alarm, just for you.")
                .font(Theme.bodyFont(12.5)).foregroundColor(Theme.text2).cardBackground()

            ForEach(store.reminders) { reminder in
                ReminderRow(reminder: reminder)
            }

            if showComposer {
                ReminderComposer(onSaved: { showComposer = false })
            } else {
                Button("+ Add a reminder") { showComposer = true }.buttonStyle(GhostButtonStyle())
            }
        }
        .overlay(alignment: .bottom) { if let t = toast { ToastView(text: t).onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil } } } }
    }

    private var pushStatusText: String {
        if !store.settings.notificationsEnabled { return "Turn on Gentle reminders to also receive updates from UrgeAway" }
        return store.settings.pushEnabled ? "Broadcast messages: connected" : pushStatus.isEmpty ? "Broadcast messages: not connected" : pushStatus
    }

    private func toggleRow(title: String, desc: String, isOn: Bool, busy: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.bodyFont(13.5, weight: .semibold)).foregroundColor(Theme.text0)
                Text(desc).font(Theme.bodyFont(11)).foregroundColor(Theme.text2)
            }
            Spacer()
            Toggle("", isOn: .init(get: { isOn }, set: { _ in action() })).labelsHidden().tint(Theme.cyan).disabled(busy).opacity(busy ? 0.6 : 1)
        }.padding(.vertical, 10)
    }

    private func toggleNotifications() {
        let turningOn = !store.settings.notificationsEnabled
        if turningOn {
            busy = true
            Task {
                let result = await NotificationsService.enable()
                await MainActor.run {
                    busy = false
                    switch result {
                    case .ok:
                        store.setSettings { $0.notificationsEnabled = true; $0.pushEnabled = true }
                        toast = "Reminders on — one gentle nudge a day"
                    case .denied: toast = "Notification permission was denied"
                    case .error: toast = "Could not enable reminders — try again"
                    }
                }
            }
        } else {
            NotificationsService.disable()
            store.setSettings { $0.notificationsEnabled = false; $0.pushEnabled = false }
            toast = "Reminders off"
        }
    }
}

private struct ReminderRow: View {
    @EnvironmentObject var store: DataStore
    let reminder: Reminder
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(timeLabel).font(Theme.bodyFont(14, weight: .semibold)).foregroundColor(Theme.text0)
                Text(reminder.message).font(Theme.bodyFont(11.5)).foregroundColor(Theme.text2).lineLimit(1)
            }
            Spacer()
            Toggle("", isOn: .init(get: { reminder.enabled }, set: { on in
                store.updateReminder(id: reminder.id) { $0.enabled = on }
                if on { NotificationsService.schedule(reminder: reminder) } else { NotificationsService.cancel(reminderId: reminder.id) }
            })).labelsHidden().tint(Theme.cyan)
            Button {
                store.deleteReminder(id: reminder.id)
                NotificationsService.cancel(reminderId: reminder.id)
            } label: { Image(systemName: "trash").foregroundColor(Theme.coral) }
        }.padding(Theme.space3).cardBackground()
    }
    private var timeLabel: String {
        let h = ((reminder.hour + 11) % 12) + 1
        let ampm = reminder.hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h, reminder.minute, ampm)
    }
}

private struct ReminderComposer: View {
    @EnvironmentObject var store: DataStore
    let onSaved: () -> Void
    @State private var time = Date()
    @State private var message = ""
    @State private var repeatDaily = true

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space3) {
            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute).labelsHidden()
            TextField("Message to yourself", text: $message)
                .padding(10).background(Theme.bg1).clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusS).stroke(Theme.line, lineWidth: 1)).foregroundColor(Theme.text0)
            Toggle("Repeat daily", isOn: $repeatDaily).tint(Theme.cyan).font(Theme.bodyFont(13))
            Button("Save reminder") {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                let r = store.addReminder(Reminder(hour: comps.hour ?? 9, minute: comps.minute ?? 0,
                                                     message: message.isEmpty ? "This is your reminder." : message,
                                                     repeatDaily: repeatDaily))
                NotificationsService.schedule(reminder: r)
                onSaved()
            }.buttonStyle(PrimaryButtonStyle())
        }.padding(Theme.space3).cardBackground()
    }
}
