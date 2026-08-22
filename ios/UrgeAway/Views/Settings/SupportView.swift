import SwiftUI

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.space4) {
                    Text("UrgeAway is a self-help tool for getting through difficult moments. It isn't a substitute for professional care, and it can't assess your situation the way a person can.")
                        .font(Theme.bodyFont(13)).foregroundColor(Theme.text1).cardBackground()

                    supportCard("Talk to someone you trust", "A friend, family member, sponsor, or peer who already knows your situation can help in ways an app can't.")
                    supportCard("Contact a qualified professional", "A doctor, therapist, or counselor can give you guidance suited to your specific situation, including any medical concerns.")
                    supportCard("Seek urgent local help if this is dangerous", "If you're in a medical emergency, experiencing severe withdrawal, or in immediate danger, contact local emergency services or go to an emergency room right away.")
                }.padding(Theme.space4)
            }
            .background(Theme.bg1.ignoresSafeArea())
            .navigationTitle("Get Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }

    private func supportCard(_ title: String, _ desc: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(Theme.bodyFont(13.5, weight: .semibold)).foregroundColor(Theme.text0)
            Text(desc).font(Theme.bodyFont(12)).foregroundColor(Theme.text2)
        }.frame(maxWidth: .infinity, alignment: .leading).cardBackground()
    }
}
