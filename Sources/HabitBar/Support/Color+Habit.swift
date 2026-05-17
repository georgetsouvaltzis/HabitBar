import HabitBarCore
import SwiftUI

extension Color {
    init(habitColor: HabitColor, colorScheme: ColorScheme) {
        let adjusted = habitColor.contrastAdjusted(forDarkMode: colorScheme == .dark)
        self.init(red: adjusted.red, green: adjusted.green, blue: adjusted.blue)
    }
}

