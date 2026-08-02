import SwiftUI

struct ResultView: View {
    @ObservedObject var vm: LearnViewModel
    var onRetry: () -> Void
    var onWrongOnly: () -> Void
    var onHome: () -> Void

    private var wrongCount: Int { vm.wrongRecords.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 正确率大卡
                VStack(spacing: 10) {
                    Image(systemName: vm.accuracy >= 0.8 ? "star.fill" : "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundColor(vm.accuracy >= 0.8 ? .yellow : Theme.mintDeep)
                    Text(percent(vm.accuracy))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.ink)
                    Text("答对 \(vm.correctCount) / \(vm.total)　·　用时 \(timeStr(vm.elapsed))")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .cardStyle()
                .padding(.horizontal, 36)
                .padding(.top, 24)

                // 错题清单
                if !vm.wrongRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("错题清单（\(wrongCount)）")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.ink)
                        ForEach(vm.wrongRecords) { rec in
                            wrongCard(rec)
                        }
                    }
                    .padding(.horizontal, 28)
                } else {
                    Text("全部答对，太棒了！🎉")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.correct)
                        .padding(.top, 8)
                }

                // 操作按钮
                VStack(spacing: 14) {
                    Button { onRetry() } label: {
                        Text("再练一轮").font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 60)
                            .background(RoundedRectangle(cornerRadius: 30).fill(Theme.mintDeep))
                    }
                    .buttonStyle(.plain)
                    Button { onWrongOnly() } label: {
                        Text("只练错题").font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.mintDeep)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(RoundedRectangle(cornerRadius: 28).stroke(Theme.mintDeep, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .disabled(wrongCount == 0)
                    .opacity(wrongCount == 0 ? 0.4 : 1)
                    Button { onHome() } label: {
                        Text("返回首页").font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.inkSoft)
                            .frame(maxWidth: .infinity).frame(height: 50)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 36).padding(.top, 8).padding(.bottom, 32)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func wrongCard(_ rec: WrongRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rec.question.word.en)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.ink)
                Spacer()
                Text(rec.question.word.theme)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Theme.sky))
            }
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("正确：\(rec.question.options[rec.question.correctIndex])")
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(Theme.correct)
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                Text("你选：\(rec.selectedZh)")
            }
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(Theme.wrong)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.inkSoft.opacity(0.12), lineWidth: 1))
    }

    private func percent(_ v: Double) -> String { "\(Int((v * 100).rounded()))%" }
    private func timeStr(_ t: TimeInterval) -> String {
        let s = Int(t); return String(format: "%d:%02d", s / 60, s % 60)
    }
}
