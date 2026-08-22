import SwiftUI
import PhotosUI

/// Ported from `renderUserDashboard` in dashboard.js: profile picture (kept
/// on-device only — no upload, matching the compressed-data-URL approach in
/// the web version), editable display name, Resistance Level summary, and a
/// capped notification history.
struct DashboardView: View {
    @EnvironmentObject var store: DataStore
    @EnvironmentObject var auth: AuthService
    @State private var editingName = false
    @State private var nameDraft = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        VStack(spacing: Theme.space4) {
            VStack(spacing: 10) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        avatarImage
                        ZStack {
                            Circle().fill(Theme.bg3).frame(width: 26, height: 26)
                            Image(systemName: "camera.fill").font(.system(size: 12)).foregroundColor(Theme.text1)
                        }
                    }
                }
                if editingName {
                    HStack {
                        TextField("Your name", text: $nameDraft)
                            .padding(8).background(Theme.bg2).clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                            .foregroundColor(Theme.text0)
                        Button("Save") { store.setProfileName(nameDraft); editingName = false }
                    }.frame(maxWidth: 240)
                } else {
                    Button { nameDraft = store.profileName; editingName = true } label: {
                        HStack(spacing: 6) {
                            Text(store.profileName.isEmpty ? "Add your name" : store.profileName)
                                .font(Theme.displayFont(17)).foregroundColor(Theme.text0)
                            Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(Theme.text2)
                        }
                    }
                }
                if let email = auth.currentUser?.email {
                    Text(email).font(Theme.bodyFont(12)).foregroundColor(Theme.text2)
                }
            }

            let rl = store.getResistanceStats()
            HStack(spacing: 0) {
                miniStat("\(rl.level)", "Level")
                miniStat("\(rl.points)", "Points")
                miniStat("\(rl.streakDays)", "Streak")
            }.cardBackground()

            VStack(alignment: .leading, spacing: 8) {
                Text("Notifications").font(Theme.bodyFont(12, weight: .semibold)).foregroundColor(Theme.text2)
                if store.notifHistory.isEmpty {
                    Text("Nothing yet.").font(Theme.bodyFont(12)).foregroundColor(Theme.text2)
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.notifHistory) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(Theme.bodyFont(12.5, weight: .semibold)).foregroundColor(Theme.text0)
                                Text(item.body).font(Theme.bodyFont(11.5)).foregroundColor(Theme.text2)
                                Text(timeAgo(item.ts)).font(Theme.bodyFont(10)).foregroundColor(Theme.text3)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                            if item.id != store.notifHistory.last?.id { Divider().background(Theme.line) }
                        }
                    }
                }
            }.cardBackground().frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: photoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) { photoData = data }
            }
        }
        .onAppear { store.markNotifViewed() }
    }

    @ViewBuilder private var avatarImage: some View {
        if let data = photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 84, height: 84).clipShape(Circle())
        } else {
            let initial = (store.profileName.first ?? Character(" ")).uppercased()
            ZStack {
                Circle().fill(LinearGradient(colors: [Theme.cyan, Theme.green], startPoint: .topLeading, endPoint: .bottomTrailing))
                if !store.profileName.isEmpty { Text(initial).font(Theme.displayFont(28)).foregroundColor(Theme.bg0) }
                else { Image(systemName: "person.fill").foregroundColor(Theme.bg0).font(.system(size: 28)) }
            }.frame(width: 84, height: 84)
        }
    }

    private func miniStat(_ num: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(num).font(Theme.displayFont(18)).foregroundColor(Theme.text0)
            Text(label).font(Theme.bodyFont(10.5)).foregroundColor(Theme.text2)
        }.frame(maxWidth: .infinity)
    }

    private func timeAgo(_ date: Date) -> String {
        let min = Int(-date.timeIntervalSinceNow / 60)
        if min < 1 { return "just now" }
        if min < 60 { return "\(min)m ago" }
        let hr = min / 60
        if hr < 24 { return "\(hr)h ago" }
        let day = hr / 24
        if day < 7 { return "\(day)d ago" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

/// Standalone bell → history sheet from Home, ported from `App.openNotifications`.
struct NotificationsHistoryView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                if store.notifHistory.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bell.slash").foregroundColor(Theme.text3).font(.system(size: 28))
                        Text("No notifications yet.").font(Theme.bodyFont(13)).foregroundColor(Theme.text2)
                    }.padding(Theme.space6)
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.notifHistory) { item in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.title).font(Theme.bodyFont(13, weight: .semibold)).foregroundColor(Theme.text0)
                                Text(item.body).font(Theme.bodyFont(12)).foregroundColor(Theme.text2)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(Theme.space3)
                            if item.id != store.notifHistory.last?.id { Divider().background(Theme.line) }
                        }
                    }.cardBackground().padding(Theme.space4)
                }
            }
            .background(Theme.bg1.ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .onAppear { store.markNotifViewed() }
        }
    }
}
