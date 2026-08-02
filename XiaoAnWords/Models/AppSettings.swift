import Foundation
import SwiftUI

/// 应用设置（UserDefaults 持久化）
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("wordCount") var wordCount: Int = 30
    @AppStorage("gradeLevel") var gradeLevelRaw: String = GradeLevel.grade1.rawValue
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("autoNext") var autoNext: Bool = false

    var gradeLevel: GradeLevel {
        get { GradeLevel(rawValue: gradeLevelRaw) ?? .grade1 }
        set { gradeLevelRaw = newValue.rawValue }
    }

    private init() {}
}
