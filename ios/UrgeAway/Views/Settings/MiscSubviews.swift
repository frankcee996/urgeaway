import SwiftUI

struct ReasonsSubview: View {
    @EnvironmentObject var store: DataStore
    @State private var newReason = ""
    var body: some View {
        SettingsSubviewScaffold(title: "My Reasons") {
            Text("Write down why this matters to you, in your own words. When an urge hits, these show up first — before anything else.")
                .font(Theme.bodyFont(12.5)).foregroundColor(Theme.text2).cardBackground()

            if !store.reasons.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(store.reasons.enumerated()), id: \.offset) { idx, r in
                        HStack {
                            Text(r).font(Theme.bodyFont(13.5)).foregroundColor(Theme.text0)
                            Spacer()
                            Button { store.deleteReason(at: idx) } label: { Image(systemName: "trash").foregroundColor(Theme.coral) }
                        }.padding(.vertical, 8)
                        if idx != store.reasons.count - 1 { Divider().background(Theme.line) }
                    }
                }.cardBackground()
            }

            HStack {
                TextField("Add a reason...", text: $newReason)
                    .padding(10).background(Theme.bg1).clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusS).stroke(Theme.line, lineWidth: 1)).foregroundColor(Theme.text0)
                Button("Add") {
                    let t = newReason.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty else { return }
                    store.addReason(t); newReason = ""
                }.buttonStyle(.borderedProminent).tint(Theme.cyanDim)
            }
        }
    }
}

struct ReachOutSubview: View {
    @EnvironmentObject var store: DataStore
    @State private var identifier = ""
    @State private var message = "Hey, could you talk for a bit? Having a hard moment."
    var body: some View {
        SettingsSubviewScaffold(title: "Reach Out") {
            Text("Set one trusted contact so the \u201CReach out\u201D option is a single tap during an urge — no digging through your contacts mid-moment.")
                .font(Theme.bodyFont(12.5)).foregroundColor(Theme.text2).cardBackground()
            VStack(alignment: .leading, spacing: Theme.space3) {
                TextField("Phone number", text: $identifier).keyboardType(.phonePad)
                    .padding(10).background(Theme.bg1).clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusS).stroke(Theme.line, lineWidth: 1)).foregroundColor(Theme.text0)
                TextField("Message", text: $message)
                    .padding(10).background(Theme.bg1).clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusS).stroke(Theme.line, lineWidth: 1)).foregroundColor(Theme.text0)
                Button("Save contact") {
                    guard !identifier.isEmpty else { return }
                    store.setReachOutContact(ReachOutContact(platform: "message", identifier: identifier, message: message))
                }.buttonStyle(PrimaryButtonStyle())
            }.cardBackground()
            if let c = store.reachOutContact {
                Text("Currently set: \(c.identifier)").font(Theme.bodyFont(11.5)).foregroundColor(Theme.text2)
            }
        }
        .onAppear { if let c = store.reachOutContact { identifier = c.identifier; message = c.message } }
    }
}

struct ProtectingSubview: View {
    @EnvironmentObject var store: DataStore
    @State private var text = ""
    var body: some View {
        SettingsSubviewScaffold(title: "What You're Protecting") {
            Text("A short phrase shown next to your streak on Home — a quiet reminder of what you're working toward.")
                .font(Theme.bodyFont(12.5)).foregroundColor(Theme.text2).cardBackground()
            HStack {
                TextField("e.g. My relationship with...", text: $text)
                    .padding(10).background(Theme.bg1).clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusS).stroke(Theme.line, lineWidth: 1)).foregroundColor(Theme.text0)
                Button("Save") { store.setStreakProtecting(text) }.buttonStyle(.borderedProminent).tint(Theme.cyanDim)
            }
        }.onAppear { text = store.streakProtecting }
    }
}

struct PrivacyDataSubview: View {
    @EnvironmentObject var store: DataStore
    @State private var showClearConfirm = false
    @State private var toast: String?
    @State private var exportURL: URL?

    var body: some View {
        SettingsSubviewScaffold(title: "Privacy & Your Data") {
            settingsSectionTitle("Privacy")
            Text("Everything you do in UrgeAway — journal entries, activity history, streaks — is stored only on this device. Nothing is uploaded, and there's no account required beyond optional sign-in for your own profile. If a future cloud-backup feature is added, it will be entirely optional and clearly explained before anything leaves your device.")
                .font(Theme.bodyFont(13.5)).foregroundColor(Theme.text1).cardBackground()

            settingsSectionTitle("Your data")
            VStack(spacing: 0) {
                HStack {
                    Text("Export data").font(Theme.bodyFont(13.5, weight: .semibold)).foregroundColor(Theme.text0)
                    Spacer()
                    Button("Export", action: exportData).buttonStyle(GhostButtonStyle(fullWidth: false))
                }.padding(.vertical, 8)
                Divider().background(Theme.line)
                HStack {
                    Text("Clear all data").font(Theme.bodyFont(13.5, weight: .semibold)).foregroundColor(Theme.coral)
                    Spacer()
                    Button("Clear") { showClearConfirm = true }.buttonStyle(GhostButtonStyle(fullWidth: false))
                }.padding(.vertical, 8)
            }.cardBackground()
        }
        .alert("Clear all UrgeAway data on this device? This can\u2019t be undone.", isPresented: $showClearConfirm) {
            Button("Clear", role: .destructive) { store.clearAllData(); toast = "All data cleared" }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $exportURLWrapper) { wrapper in
            ShareSheet(items: [wrapper.url])
        }
        .overlay(alignment: .bottom) { if let t = toast { ToastView(text: t) } }
    }

    private var exportURLWrapper: IdentifiableURL? {
        get { exportURL.map(IdentifiableURL.init) }
        nonmutating set { exportURL = newValue?.url }
    }

    private func exportData() {
        let export = store.exportAll()
        guard let data = try? JSONEncoder.iso.encode(export) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("urgeaway-export.json")
        try? data.write(to: url)
        exportURL = url
    }
}

private struct IdentifiableURL: Identifiable { let url: URL; var id: String { url.absoluteString } }

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

struct AboutSubview: View {
    var body: some View {
        SettingsSubviewScaffold(title: "About UrgeAway") {
            VStack(alignment: .leading, spacing: 4) {
                Text("UrgeAway v1.0 — MVP").font(Theme.bodyFont(13, weight: .semibold)).foregroundColor(Theme.text0)
                Text("UrgeAway offers supportive distraction, grounding, and reflection tools. It is not a medical treatment and does not diagnose or guarantee outcomes.")
                    .font(Theme.bodyFont(13)).foregroundColor(Theme.text2)
            }.cardBackground()
        }
    }
}
