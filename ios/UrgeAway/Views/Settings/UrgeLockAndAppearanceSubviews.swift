import SwiftUI

/// iOS has no Guided Access API — only the person can turn it on, manually,
/// via Settings → Accessibility → Guided Access. This subview explains that
/// plainly (matching the web version's iOS branch of `renderUrgeLockSubview`)
/// instead of offering a fake in-app "set up" control.
struct UrgeLockSubview: View {
    @EnvironmentObject var store: DataStore
    @State private var showSteps = false

    var body: some View {
        SettingsSubviewScaffold(title: "Urge Lock") {
            settingsSectionTitle("Urge Lock")
            Text("For urges you rate 7 or higher, Urge Lock starts a timed, focused session. iOS doesn\u2019t let any app lock itself to the screen — only you can do that, using Apple\u2019s Guided Access. UrgeAway can\u2019t turn it on or off for you.")
                .font(Theme.bodyFont(12.5)).foregroundColor(Theme.text2).cardBackground()

            settingsSectionTitle("Status")
            VStack(alignment: .leading, spacing: 2) {
                Text(store.urgeLockSetupDone ? "You\u2019ve reviewed the steps" : "Manual — set up in iPhone Settings")
                    .font(Theme.bodyFont(13, weight: .semibold)).foregroundColor(Theme.text0)
                Text("Apple\u2019s Guided Access").font(Theme.bodyFont(11)).foregroundColor(Theme.text2)
            }.frame(maxWidth: .infinity, alignment: .leading).cardBackground()

            Button("HOW TO TURN ON GUIDED ACCESS") {
                showSteps.toggle()
                store.setUrgeLockSetupDone()
            }.buttonStyle(GhostButtonStyle())

            if showSteps {
                VStack(alignment: .leading, spacing: 6) {
                    Text("1. Open the iPhone **Settings** app")
                    Text("2. Go to **Accessibility → Guided Access** and turn it on")
                    Text("3. Set a Guided Access passcode")
                    Text("4. Whenever you start Urge Lock in UrgeAway, triple-click the side button to lock yourself into the app for the session")
                }.font(Theme.bodyFont(12.5)).foregroundColor(Theme.text2).cardBackground()
            }
        }
    }
}

struct AppearanceSubview: View {
    @EnvironmentObject var store: DataStore
    var body: some View {
        SettingsSubviewScaffold(title: "Appearance") {
            settingsSectionTitle("Theme")
            HStack(spacing: 8) {
                ForEach([("system", "System"), ("light", "Light"), ("dark", "Dark")], id: \.0) { key, label in
                    Button {
                        store.setSettings { $0.theme = key }
                    } label: {
                        Text(label).font(Theme.bodyFont(13, weight: .semibold))
                            .foregroundColor(store.settings.theme == key ? Theme.bg0 : Theme.text1)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(store.settings.theme == key ? AnyShapeStyle(Theme.cyan) : AnyShapeStyle(Theme.bg3))
                            .clipShape(Capsule())
                    }
                }
            }.cardBackground()
        }
    }
}
