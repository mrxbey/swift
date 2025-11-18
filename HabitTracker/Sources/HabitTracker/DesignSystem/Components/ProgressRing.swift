//
// ProgressRing.swift
// HabitTracker
//

import SwiftUI

/// Circular progress indicator
public struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat

    public init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 60
    ) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    Theme.Colors.separator.opacity(0.3),
                    lineWidth: lineWidth
                )

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Theme.Colors.progressGradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.Animation.spring, value: progress)
        }
        .frame(width: size, height: size)
    }
}

#if DEBUG
#Preview("Progress Ring") {
    VStack(spacing: Theme.Spacing.large) {
        ProgressRing(progress: 0.0)
        ProgressRing(progress: 0.33)
        ProgressRing(progress: 0.66)
        ProgressRing(progress: 1.0)
    }
    .padding()
}
#endif
