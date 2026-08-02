import SwiftUI

// MARK: - 清新风格主题
enum Theme {
    // 主色：薄荷绿
    static let mint = Color(red: 0.40, green: 0.79, blue: 0.71)
    static let mintDeep = Color(red: 0.20, green: 0.55, blue: 0.48)
    // 天空蓝
    static let sky = Color(red: 0.45, green: 0.75, blue: 0.93)
    // 柔和红/绿（正误反馈）
    static let correct = Color(red: 0.45, green: 0.78, blue: 0.52)
    static let wrong = Color(red: 0.92, green: 0.55, blue: 0.55)
    // 背景与卡片
    static let bg = Color(red: 0.97, green: 0.99, blue: 0.98)
    static let card = Color.white
    static let ink = Color(red: 0.18, green: 0.22, blue: 0.26)
    static let inkSoft = Color(red: 0.45, green: 0.50, blue: 0.55)

    static let titleFont = Font.system(size: 34, weight: .bold, design: .rounded)
    static let wordFont = Font.system(size: 64, weight: .bold, design: .rounded)
    static let optionFont = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 20, weight: .medium, design: .rounded)

    static let cardCorner: CGFloat = 24
    static let optionCorner: CGFloat = 18
    static let optionHeight: CGFloat = 84
}

// 卡片样式
struct CardBackground: ViewModifier {
    var color: Color = Theme.card
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .fill(color)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            )
    }
}

extension View {
    func cardStyle(_ color: Color = Theme.card) -> some View {
        modifier(CardBackground(color: color))
    }
}
