import SwiftUI

struct JournalTabView: View {
    @EnvironmentObject var store: DataStore
    @State private var text = ""
    @State private var selectedPrompt: String?
    @State private var expandedIds: Set<String> = []
    @State private var toast: String?

    private let prompts = [
        "What triggered this moment?", "What am I feeling right now?", "What do I actually need?",
        "What would future me want me to do next?", "What helped last time?",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space4) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Journal").font(Theme.displayFont(24)).foregroundColor(Theme.text0)
                Text("Private. Stored only on this device.").font(Theme.bodyFont(13)).foregroundColor(Theme.text2)
            }

            VStack(alignment: .leading, spacing: Theme.space2) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(prompts, id: \.self) { p in
                            Button {
                                selectedPrompt = p
                            } label: {
                                Text(p).font(Theme.bodyFont(11, weight: .medium))
                                    .foregroundColor(selectedPrompt == p ? Theme.cyan : Theme.text2)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(selectedPrompt == p ? Theme.cyan.opacity(0.14) : Theme.bg3)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                TextEditor(text: $text)
                    .frame(minHeight: 56).padding(6).scrollContentBackground(.hidden)
                    .background(Theme.bg1).clipShape(RoundedRectangle(cornerRadius: Theme.radiusS))
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusS).stroke(Theme.line, lineWidth: 1))
                    .foregroundColor(Theme.text0)
                Button("Save entry") {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { toast = "Write something first, or tap a prompt for ideas."; return }
                    store.addJournalEntry(prompt: selectedPrompt ?? "Free write", text: trimmed)
                    text = ""; selectedPrompt = nil; toast = "Entry saved"
                }.buttonStyle(PrimaryButtonStyle())
            }.padding(Theme.space3).cardBackground()

            Text("Past entries").font(Theme.bodyFont(12, weight: .semibold)).foregroundColor(Theme.text2)

            if store.journal.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed").foregroundColor(Theme.text3).font(.system(size: 28))
                    Text("Nothing written yet. Whatever's on your mind is welcome here.")
                        .font(Theme.bodyFont(12)).foregroundColor(Theme.text2).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity).padding(Theme.space5)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(store.journal) { entry in
                            Button {
                                if expandedIds.contains(entry.id) { expandedIds.remove(entry.id) } else { expandedIds.insert(entry.id) }
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(Theme.bodyFont(10.5)).foregroundColor(Theme.text3)
                                    Text(entry.prompt).font(Theme.bodyFont(11.5, weight: .semibold)).foregroundColor(Theme.cyan)
                                    Text(entry.text).font(Theme.bodyFont(13)).foregroundColor(Theme.text1)
                                        .lineLimit(expandedIds.contains(entry.id) ? nil : 2)
                                }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10)
                            }
                            if entry.id != store.journal.last?.id { Divider().background(Theme.line) }
                        }
                    }.padding(.horizontal, Theme.space3).cardBackground()
                }
            }
        }
        .padding(Theme.space4)
        .background(Theme.bg1.ignoresSafeArea())
        .overlay(alignment: .bottom) { if let t = toast { ToastView(text: t).onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toast = nil } } } }
    }
}

struct ToastView: View {
    let text: String
    var body: some View {
        Text(text).font(Theme.bodyFont(12.5, weight: .semibold)).foregroundColor(Theme.text0)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Theme.bg3).clipShape(Capsule())
            .padding(.bottom, 30)
    }
}
