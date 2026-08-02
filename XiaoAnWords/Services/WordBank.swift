import Foundation

/// 词库加载服务：从 Bundle 读取 words.json
enum WordBank {
    static let all: [Word] = load()

    private static func load() -> [Word] {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json") else {
            assertionFailure("words.json 未找到")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Word].self, from: data)
        } catch {
            assertionFailure("词库解析失败: \(error)")
            return []
        }
    }

    /// 取指定年级层级的词（common 始终包含）
    static func words(for level: Int) -> [Word] {
        all.filter { $0.level == level || $0.level == 0 }
    }

    /// 词数统计
    static func count(for level: Int) -> Int { words(for: level).count }
}
