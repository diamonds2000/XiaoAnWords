import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("学习") {
                    Picker("每轮单词数", selection: $settings.wordCount) {
                        Text("10").tag(10); Text("20").tag(20)
                        Text("30").tag(30); Text("50").tag(50)
                    }.pickerStyle(.segmented)
                    Picker("学习年级", selection: Binding(
                        get: { settings.gradeLevel },
                        set: { settings.gradeLevel = $0 }
                    )) {
                        ForEach(GradeLevel.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                }
                Section("答题") {
                    Toggle("音效反馈", isOn: $settings.soundEnabled)
                    Toggle("答对后自动下一题", isOn: $settings.autoNext)
                }
                Section {
                    Button(role: .destructive) { showResetAlert = true } label: {
                        Label("重置学习记录", systemImage: "trash")
                    }
                } footer: {
                    Text("重置后所有错词统计清空，无法恢复。")
                }
                Section {
                    Text("小安背单词 · v1.0").font(.footnote).foregroundColor(Theme.inkSoft)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .alert("确认重置？", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) {}
            Button("重置", role: .destructive) { resetStats() }
        } message: {
            Text("将清空全部错词统计与学习进度，此操作不可撤销。")
        }
    }

    private func resetStats() {
        do {
            let all = try modelContext.fetch(FetchDescriptor<WordStats>())
            for s in all { modelContext.delete(s) }
            try modelContext.save()
        } catch {
            print("重置失败: \(error)")
        }
    }
}
