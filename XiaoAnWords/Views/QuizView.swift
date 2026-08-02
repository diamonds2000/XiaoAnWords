import SwiftUI

struct QuizView: View {
    @ObservedObject var vm: LearnViewModel
    var onQuit: () -> Void
    var onFinished: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 顶栏：退出 + 进度
            HStack(spacing: 16) {
                Button { onQuit() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.inkSoft.opacity(0.6))
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vm.index + 1) / \(vm.total)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.inkSoft)
                    ProgressView(value: vm.progress + (vm.isAnswered ? Double(1)/Double(max(vm.total,1)) : 0), total: 1)
                        .tint(Theme.mintDeep)
                        .frame(height: 8)
                }
                Text("\(vm.correctCount) ✓")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.correct)
            }
            .padding(.horizontal, 28).padding(.top, 20)

            Spacer()

            // 单词卡（仅英文）
            if let q = vm.current {
                VStack(spacing: 10) {
                    Text(q.word.en)
                        .font(Theme.wordFont)
                        .foregroundColor(Theme.ink)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    // 正误反馈文字
                    if vm.isAnswered {
                        if vm.selected == q.correctIndex {
                            Text("答对了！").font(Theme.bodyFont).foregroundColor(Theme.correct)
                        } else {
                            Text("正确释义：\(q.options[q.correctIndex])")
                                .font(Theme.bodyFont).foregroundColor(Theme.wrong)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .cardStyle()
                .padding(.horizontal, 36)
            }

            Spacer()

            // 四选项 2×2
            if let q = vm.current {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(Array(q.options.enumerated()), id: \.offset) { idx, opt in
                        optionButton(idx: idx, text: opt)
                    }
                }
                .padding(.horizontal, 28)

                // 下一题/查看结果按钮：始终显示，未答题时禁用（手动模式）
                if !vm.autoNext {
                    Button { vm.next() } label: {
                        Text(vm.index + 1 < vm.total ? "下一题" : "查看结果")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .fill(vm.isAnswered ? Theme.mintDeep : Theme.mintDeep.opacity(0.4))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!vm.isAnswered)
                    .animation(.easeInOut(duration: 0.2), value: vm.isAnswered)
                    .padding(.horizontal, 28).padding(.top, 18)
                }
            }
            Spacer().frame(height: 28)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onChange(of: vm.finished) { _, finished in
            if finished { onFinished() }
        }
    }

    private func optionButton(idx: Int, text: String) -> some View {
        let q = vm.current
        let isCorrect = idx == q?.correctIndex
        let isSelected = idx == vm.selected
        let bg: Color = {
            if !vm.isAnswered { return Theme.card }
            if isCorrect { return Theme.correct.opacity(0.22) }
            if isSelected { return Theme.wrong.opacity(0.22) }
            return Theme.card
        }()
        let border: Color = {
            if !vm.isAnswered { return Theme.mint.opacity(0.35) }
            if isCorrect { return Theme.correct }
            if isSelected { return Theme.wrong }
            return Theme.inkSoft.opacity(0.2)
        }()
        let fg: Color = {
            if vm.isAnswered && (isCorrect || isSelected) { return Theme.ink }
            return Theme.ink
        }()

        return Button {
            vm.answer(idx)
        } label: {
            HStack {
                if vm.isAnswered && isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.correct)
                } else if vm.isAnswered && isSelected && !isCorrect {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Theme.wrong)
                }
                Text(text)
                    .font(Theme.optionFont)
                    .foregroundColor(fg)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: Theme.optionHeight, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.optionCorner, style: .continuous).fill(bg))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.optionCorner, style: .continuous)
                    .stroke(border, lineWidth: 2.5)
            )
        }
        .disabled(vm.isAnswered)
        .buttonStyle(.plain)
    }
}
