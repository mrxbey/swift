//
// Theme.swift
// HabitTracker
//

import SwiftUI

/// Central theme configuration for the app
public enum Theme {

    // MARK: - Colors

    public enum Colors {
        // Primary brand colors
        public static let primary = Color("Primary", bundle: .module)
        public static let secondary = Color("Secondary", bundle: .module)
        public static let accent = Color("Accent", bundle: .module)

        // Semantic colors
        public static let success = Color.green
        public static let warning = Color.orange
        public static let error = Color.red
        public static let info = Color.blue

        // Background colors
        public static let background = Color("Background", bundle: .module)
        public static let secondaryBackground = Color("SecondaryBackground", bundle: .module)
        public static let tertiaryBackground = Color("TertiaryBackground", bundle: .module)

        // Text colors
        public static let text = Color("Text", bundle: .module)
        public static let secondaryText = Color("SecondaryText", bundle: .module)
        public static let tertiaryText = Color("TertiaryText", bundle: .module)

        // UI element colors
        public static let separator = Color("Separator", bundle: .module)
        public static let border = Color("Border", bundle: .module)

        // Area colors (predefined palette)
        public static let areaColors: [Color] = [
            Color(hex: "FF6B6B"), // Red
            Color(hex: "4ECDC4"), // Teal
            Color(hex: "95E1D3"), // Mint
            Color(hex: "F38181"), // Pink
            Color(hex: "AA96DA"), // Purple
            Color(hex: "FCBAD3"), // Light Pink
            Color(hex: "A8D8EA"), // Sky Blue
            Color(hex: "FFCCCC"), // Peach
            Color(hex: "DCD6F7"), // Lavender
            Color(hex: "F9ED69"), // Yellow
        ]

        // Goal status colors
        public static func statusColor(_ status: OccurrenceStatus) -> Color {
            switch status {
            case .pending: return .gray
            case .completed: return success
            case .skipped: return info
            case .missed: return error
            case .cancelled: return warning
            }
        }

        // Progress gradient
        public static let progressGradient = LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Typography

    public enum Typography {
        // Headings
        public static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        public static let title1 = Font.system(.title, design: .rounded, weight: .bold)
        public static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
        public static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)

        // Body
        public static let body = Font.system(.body, design: .default, weight: .regular)
        public static let bodyBold = Font.system(.body, design: .default, weight: .semibold)

        // Secondary
        public static let callout = Font.system(.callout, design: .default, weight: .regular)
        public static let footnote = Font.system(.footnote, design: .default, weight: .regular)
        public static let caption = Font.system(.caption, design: .default, weight: .regular)
        public static let caption2 = Font.system(.caption2, design: .default, weight: .regular)

        // Custom
        public static let emoji = Font.system(size: 40)
        public static let emojiLarge = Font.system(size: 60)
        public static let number = Font.system(size: 32, weight: .bold, design: .rounded)
    }

    // MARK: - Spacing

    public enum Spacing {
        public static let xxxSmall: CGFloat = 2
        public static let xxSmall: CGFloat = 4
        public static let xSmall: CGFloat = 8
        public static let small: CGFloat = 12
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 24
        public static let xLarge: CGFloat = 32
        public static let xxLarge: CGFloat = 48
        public static let xxxLarge: CGFloat = 64
    }

    // MARK: - Corner Radius

    public enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let large: CGFloat = 16
        public static let xLarge: CGFloat = 24
        public static let circle: CGFloat = 1000
    }

    // MARK: - Shadows

    public enum Shadow {
        public static let small = ShadowStyle(radius: 4, y: 2)
        public static let medium = ShadowStyle(radius: 8, y: 4)
        public static let large = ShadowStyle(radius: 16, y: 8)

        public struct ShadowStyle {
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat

            init(radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
                self.radius = radius
                self.x = x
                self.y = y
            }
        }
    }

    // MARK: - Animation

    public enum Animation {
        public static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        public static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        public static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }

    // MARK: - Icons

    public enum Icons {
        // Navigation
        public static let today = "calendar"
        public static let areas = "folder"
        public static let insights = "chart.bar"
        public static let programs = "star"
        public static let settings = "gearshape"

        // Actions
        public static let add = "plus.circle.fill"
        public static let edit = "pencil"
        public static let delete = "trash"
        public static let more = "ellipsis.circle"

        // Status
        public static let complete = "checkmark.circle.fill"
        public static let pending = "circle"
        public static let skip = "arrow.right.circle"
        public static let missed = "xmark.circle"

        // Goal types
        public static let habit = "repeat"
        public static let task = "checkmark.circle"
        public static let measure = "chart.bar"

        // Features
        public static let water = "drop.fill"
        public static let reflection = "book.pages"
        public static let buddy = "person.2.fill"
        public static let streak = "flame.fill"
        public static let points = "star.fill"
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extension

extension View {
    /// Applies the standard card style
    public func cardStyle() -> some View {
        self
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    /// Applies the primary button style
    public func primaryButtonStyle() -> some View {
        self
            .font(Theme.Typography.bodyBold)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.primary)
            .cornerRadius(Theme.CornerRadius.medium)
    }

    /// Applies the secondary button style
    public func secondaryButtonStyle() -> some View {
        self
            .font(Theme.Typography.bodyBold)
            .foregroundColor(Theme.Colors.primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.Colors.primary.opacity(0.1))
            .cornerRadius(Theme.CornerRadius.medium)
    }
}
