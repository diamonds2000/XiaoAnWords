import Foundation
import SwiftData

/// 单词学习统计（持久化，跨会话）
@Model
final class WordStats {
    @Attribute(.unique) var wordId: String
    var seenCount: Int
    var correctCount: Int
    var wrongCount: Int
    var correctStreak: Int
    var lastSeen: Date?

    init(wordId: String) {
        self.wordId = wordId
        self.seenCount = 0
        self.correctCount = 0
        self.wrongCount = 0
        self.correctStreak = 0
        self.lastSeen = nil
    }

    var errorRate: Double {
        seenCount > 0 ? Double(wrongCount) / Double(seenCount) : 0
    }
    var accuracy: Double {
        seenCount > 0 ? Double(correctCount) / Double(seenCount) : 0
    }
}
