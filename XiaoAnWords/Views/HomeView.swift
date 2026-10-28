import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allStats: [WordStats]
    @StateObject private var settings = AppSettings.shared

    @State private var phase: Phase = .home
    @State private var vm: LearnViewModel? = nil
    @State private var wrongOnlyMode = false
    @State private var showEmptyAlert = false
    @State private var showSettings = false

    enum Phase { case home, quiz, result }

    private var poolCount: Int { WordBank.count(for: settings.gradeLevel.level) }
    private var learnedCount: Int { allStats.filter { $0.seenCount > 0 }.count }
    private var masteredCount: Int {
        allStats.filter { $0.seenCount > 0 && $0.accuracy >= 0.8 && $0.correctStreak >= 3 }.count
    }
    private var wrongCount: Int { allStats.filter { $0.wrongCount > 0 }.count }
    private var overallAccuracy: Double {
        let s = allStats.reduce(0) { $0 + $1.seenCount }
        let c = allStats.reduce(0) { $0 + $1.correctCount }
        return s > 0 ? Double(c) / Double(s) : 0
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            switch phase {
            case .home: homeContent
            case .quiz: if let vm { QuizView(vm: vm, onQuit: backHome, onFinished: { phase = .result }) } else { homeContent }
            case .result: if let vm { ResultView(vm: vm, onRetry: { start(wrongOnly: false) }, onWrongOnly: { start(wrongOnly: true) }, onHome: backHome) } else { homeContent }
            }
        }
        .preferredColorScheme(.light)
        .task {
            // 调试/演示：--demo-grade <1-4> 选年级；--demo-quiz 直接进入一轮答题
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "--demo-grade"), i + 1 < args.count,
               let lv = Int(args[i + 1]) {
                settings.gradeLevel = GradeLevel.allCases.first { $0.level == lv } ?? .grade1
            }
            if phase == .home, args.contains("--demo-quiz") {
                start(wrongOnly: false)
            }
        }
        .alert("没有可学的单词", isPresented: $showEmptyAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(wrongOnlyMode ? "当前年级还没有错词，先正常学习一轮吧。" : "词库为空，请检查年级设置。")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(settings)
        }
    }

    // MARK: - 首页
    private var homeContent: some View {
        VStack(spacing: 0) {
            // 顶栏
            HStack {
                Text("小安背单词").font(Theme.titleFont).foregroundColor(Theme.ink)
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Theme.mintDeep)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28).padding(.top, 20)

            Spacer()

            // 中央卡片
            VStack(spacing: 24) {
                ZStack {
                    Circle().fill(Theme.mint.opacity(0.18)).frame(width: 140, height: 140)
                    Image(systemName: "book.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(Theme.mintDeep)
                }

                VStack(spacing: 8) {
                    Text("今日学习").font(Theme.bodyFont).foregroundColor(Theme.inkSoft)
                    Text("\(settings.wordCount) 个单词")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.ink)
                    Text("年级：\(settings.gradeLevel.rawValue) · 词库 \(poolCount) 词")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.inkSoft)
                }

                // 开始按钮
                Button { start(wrongOnly: false) } label: {
                    Text("开始学习")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Theme.mintDeep)
                        )
                        .shadow(color: Theme.mintDeep.opacity(0.35), radius: 12, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)

                // 只练错题
                Button { start(wrongOnly: true) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("只练错题（\(wrongCount)）")
                    }
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(wrongCount > 0 ? Theme.mintDeep : Theme.inkSoft)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(wrongCount > 0 ? Theme.mintDeep : Theme.inkSoft.opacity(0.3), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .disabled(wrongCount == 0)
                .padding(.horizontal, 12)
            }
            .padding(28)
            .cardStyle()
            .padding(.horizontal, 36)

            Spacer()

            // 底部统计
            HStack(spacing: 0) {
                statItem(title: "已学", value: "\(learnedCount)")
                Divider().frame(height: 36)
                statItem(title: "已掌握", value: "\(masteredCount)")
                Divider().frame(height: 36)
                statItem(title: "正确率", value: percent(overallAccuracy))
            }
            .padding(.horizontal, 28).padding(.bottom, 28)
        }
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(Theme.ink)
            Text(title).font(.system(size: 13, weight: .medium)).foregroundColor(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
    }

    private func percent(_ v: Double) -> String {
        let p = Int((v * 100).rounded())
        return "\(p)%"
    }

    // MARK: - 流程控制
    private func start(wrongOnly: Bool) {
        wrongOnlyMode = wrongOnly
        let qs = SessionBuilder.build(level: settings.gradeLevel.level,
                                      count: settings.wordCount,
                                      wrongOnly: wrongOnly,
                                      modelContext: modelContext)
        guard !qs.isEmpty else {
            showEmptyAlert = true
            return
        }
        vm = LearnViewModel(questions: qs, modelContext: modelContext,
                            soundEnabled: settings.soundEnabled, autoNext: settings.autoNext)
        phase = .quiz
    }

    private func backHome() {
        vm = nil
        phase = .home
    }
}
