import Foundation
import SwiftData
import SwiftUI
import AudioToolbox

/// 构建/读取本轮题目
enum SessionBuilder {
    static func build(level: Int, count: Int, wrongOnly: Bool,
                      modelContext: ModelContext) -> [QuizQuestion] {
        let pool = WordBank.words(for: level)
        let desc = FetchDescriptor<WordStats>()
        let all = (try? modelContext.fetch(desc)) ?? []
        let dict = Dictionary(uniqueKeysWithValues: all.map { ($0.wordId, $0) })
        return QuizEngine.makeSession(pool: pool, stats: dict,
                                      count: count, wrongOnly: wrongOnly)
    }
}

/// 答题状态机
@MainActor
final class LearnViewModel: ObservableObject {
    let questions: [QuizQuestion]
    private let modelContext: ModelContext
    private let soundEnabled: Bool
    let autoNext: Bool

    @Published var index = 0
    @Published var selected: Int? = nil
    @Published var isAnswered = false
    @Published var correctCount = 0
    @Published var wrongRecords: [WrongRecord] = []
    @Published var finished = false
    @Published var startTime = Date()

    init(questions: [QuizQuestion], modelContext: ModelContext,
         soundEnabled: Bool, autoNext: Bool) {
        self.questions = questions
        self.modelContext = modelContext
        self.soundEnabled = soundEnabled
        self.autoNext = autoNext
    }

    var current: QuizQuestion? {
        guard index < questions.count else { return nil }
        return questions[index]
    }
    var total: Int { questions.count }
    var progress: Double { total == 0 ? 0 : Double(index) / Double(total) }

    func answer(_ optionIndex: Int) {
        guard !isAnswered, let q = current else { return }
        selected = optionIndex
        isAnswered = true
        let correct = (optionIndex == q.correctIndex)
        if correct { correctCount += 1 }
        else { wrongRecords.append(WrongRecord(question: q, selectedZh: q.options[optionIndex])) }
        recordStats(wordId: q.word.id, correct: correct)
        playFeedback(correct: correct)

        if autoNext {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.next()
            }
        }
    }

    func next() {
        guard isAnswered else { return }
        if index + 1 < total {
            index += 1
            selected = nil
            isAnswered = false
        } else {
            finished = true
            save()
        }
    }

    // MARK: - 统计更新
    private func recordStats(wordId: String, correct: Bool) {
        let desc = FetchDescriptor<WordStats>(predicate: #Predicate { $0.wordId == wordId })
        let existing = (try? modelContext.fetch(desc))?.first
        let s = existing ?? WordStats(wordId: wordId)
        if existing == nil { modelContext.insert(s) }
        s.seenCount += 1
        if correct {
            s.correctCount += 1
            s.correctStreak += 1
        } else {
            s.wrongCount += 1
            s.correctStreak = 0
        }
        s.lastSeen = Date()
    }

    private func save() {
        try? modelContext.save()
    }

    private func playFeedback(correct: Bool) {
        guard soundEnabled else { return }
        // 系统短音：正确 1004(也可用 1057)，错误 1003
        let id = correct ? SystemSoundID(1057) : SystemSoundID(1003)
        AudioServicesPlaySystemSound(id)
    }

    var accuracy: Double {
        total == 0 ? 0 : Double(correctCount) / Double(total)
    }
    var elapsed: TimeInterval { Date().timeIntervalSince(startTime) }
}
