import Foundation

public struct HabitColor: Codable, Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
    }

    public static let green = HabitColor(red: 0.20, green: 0.70, blue: 0.32)
    public static let blue = HabitColor(red: 0.22, green: 0.48, blue: 0.95)
    public static let cyan = HabitColor(red: 0.18, green: 0.65, blue: 0.85)
    public static let violet = HabitColor(red: 0.50, green: 0.39, blue: 0.88)
    public static let orange = HabitColor(red: 0.95, green: 0.45, blue: 0.18)
}

public extension HabitColor {
    func contrastAdjusted(forDarkMode isDarkMode: Bool) -> HabitColor {
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        if isDarkMode, luminance < 0.42 {
            return mixed(with: HabitColor(red: 1, green: 1, blue: 1), amount: 0.35)
        }

        if !isDarkMode, luminance > 0.78 {
            return mixed(with: HabitColor(red: 0, green: 0, blue: 0), amount: 0.25)
        }

        return self
    }

    private func mixed(with other: HabitColor, amount: Double) -> HabitColor {
        HabitColor(
            red: red + (other.red - red) * amount,
            green: green + (other.green - green) * amount,
            blue: blue + (other.blue - blue) * amount
        )
    }
}

