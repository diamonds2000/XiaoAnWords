import Foundation

/// 词库单元（静态，来自 words.json）
struct Word: Codable, Identifiable, Hashable {
    let id: String
    let en: String
    let zh: String
    /// "1A"..."3B" 或 "common"（全学段短语/代词冠词，所有年级共享）
    let grade: String
    let theme: String
    /// 同义组：同组词意思相同，不会互为干扰项（如 a/an、cannot/can't）
    let syn: String?

    /// 年级层级：1=一年级, 2=二年级, 3=三年级；common 归入所有层级
    var level: Int {
        switch grade {
        case "1A", "1B": return 1
        case "2A", "2B": return 2
        case "3A", "3B": return 3
        default: return 0   // common
        }
    }
}

/// 学习年级（用户可选项）
enum GradeLevel: String, CaseIterable, Identifiable {
    case grade1 = "一年级"
    case grade2 = "二年级"
    case grade3 = "三年级"
    var id: String { rawValue }
    var level: Int {
        switch self {
        case .grade1: return 1
        case .grade2: return 2
        case .grade3: return 3
        }
    }
}
