import Foundation

/// 一道题
struct QuizQuestion: Identifiable {
    let id = UUID()
    let word: Word
    let options: [String]   // 4 个中文释义
    let correctIndex: Int
}

/// 错题记录（含当时所选错误项）
struct WrongRecord: Identifiable {
    let id = UUID()
    let question: QuizQuestion
    let selectedZh: String
}

/// 出题引擎：错词加权抽取 + 同主题干扰项（语义去重）
enum QuizEngine {

    /// 生成本轮题目
    /// - Parameters:
    ///   - pool: 候选词池（已按年级筛选，含 common）
    ///   - stats: 各词统计 [wordId: WordStats]
    ///   - count: 本轮题数
    ///   - wrongOnly: 仅练错词模式（只取 wrongCount>0 的词）
    static func makeSession(pool: [Word],
                            stats: [String: WordStats],
                            count: Int,
                            wrongOnly: Bool = false) -> [QuizQuestion] {
        var candidates = wrongOnly
            ? pool.filter { (stats[$0.id]?.wrongCount ?? 0) > 0 }
            : pool
        guard !candidates.isEmpty else { return [] }
        // 若错词模式词数不足，直接用全部错词
        let n = min(count, candidates.count)

        let selected: [Word]
        if wrongOnly {
            selected = Array(candidates.shuffled().prefix(n))
        } else {
            selected = pickWeighted(candidates, stats: stats, count: n)
        }

        return selected.shuffled().map { makeQuestion(word: $0, all: pool) }
    }

    // MARK: - 加权抽取
    private static func pickWeighted(_ pool: [Word],
                                     stats: [String: WordStats],
                                     count: Int) -> [Word] {
        var remaining = pool
        var result: [Word] = []

        // 1) 强制优先：wrongCount >= 2 的词，上限 count 的 50%
        let forcedCap = max(1, count / 2)
        var forced = remaining.filter { (stats[$0.id]?.wrongCount ?? 0) >= 2 }.shuffled()
        if forced.count > forcedCap { forced = Array(forced.prefix(forcedCap)) }
        for w in forced {
            result.append(w)
            remaining.removeAll { $0.id == w.id }
        }

        // 2) 加权随机不放回补足
        while result.count < count, !remaining.isEmpty {
            let weights = remaining.map { weight(of: $0, stats: stats) }
            let total = weights.reduce(0, +)
            let r = Double.random(in: 0..<max(total, 0.0001))
            var acc = 0.0
            for (i, w) in remaining.enumerated() {
                acc += weights[i]
                if r < acc {
                    result.append(w)
                    remaining.remove(at: i)
                    break
                }
            }
        }
        return result
    }

    /// 权重：新词 1.0；其余 1.0 + 5.0 × 错误率（全错→6.0）
    private static func weight(of word: Word, stats: [String: WordStats]) -> Double {
        guard let s = stats[word.id], s.seenCount > 0 else { return 1.0 }
        return 1.0 + 5.0 * (Double(s.wrongCount) / Double(s.seenCount))
    }

    // MARK: - 干扰项生成
    // 关键：只阻挡「真正同义组」(syn != nil)；syn == nil 的词互不排斥。
    // 每次抽取都实时校验 zh 与同义组去重，避免出现重复释义/相同干扰项。
    private static func makeQuestion(word: Word, all: [Word]) -> QuizQuestion {
        var distractors: [Word] = []
        var usedZh: Set<String> = [word.zh]                 // 释义去重（含答案）
        var usedSynGroups: Set<String> = []                  // 仅记录非 nil 同义组
        if let s = word.syn { usedSynGroups.insert(s) }

        func canTake(_ w: Word) -> Bool {
            guard w.id != word.id else { return false }
            guard !distractors.contains(where: { $0.id == w.id }) else { return false }
            guard !usedZh.contains(w.zh) else { return false }                  // 释义不重复
            if let g = w.syn, usedSynGroups.contains(g) { return false }        // 同义组不重复
            return true
        }

        @discardableResult
        func take(_ w: Word) -> Bool {
            guard canTake(w) else { return false }
            distractors.append(w)
            usedZh.insert(w.zh)
            if let g = w.syn { usedSynGroups.insert(g) }
            return true
        }

        let others = all.filter { $0.id != word.id }
        // 候选优先级：同主题 > 同年级(+common) > 其余；各桶内随机
        let sameTheme = others.filter { $0.theme == word.theme }.shuffled()
        let sameLevel = others
            .filter { $0.theme != word.theme && ($0.level == word.level || $0.level == 0) }
            .shuffled()
        let rest = others
            .filter { $0.theme != word.theme && $0.level != word.level && $0.level != 0 }
            .shuffled()

        for w in sameTheme + sameLevel + rest where distractors.count < 3 { take(w) }

        // 兜底：极少数情况下仍不足 3（如词库极小），放宽同义组限制、仅保证释义不重复
        if distractors.count < 3 {
            for w in all.shuffled() where distractors.count < 3 {
                guard w.id != word.id,
                      !distractors.contains(where: { $0.id == w.id }),
                      !usedZh.contains(w.zh) else { continue }
                distractors.append(w)
                usedZh.insert(w.zh)
            }
        }

        let options = ([word] + distractors).shuffled()
        let optionsZh = options.map { $0.zh }
        let correctIndex = optionsZh.firstIndex(of: word.zh) ?? 0
        return QuizQuestion(word: word, options: optionsZh, correctIndex: correctIndex)
    }
}
