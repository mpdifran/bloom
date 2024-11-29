//
//  VitalStatusBarView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-26.
//

import SwiftUI
import DataContainer

private extension CGFloat {
    static let cornerRadius: CGFloat = 5
    static let expandedRectangleWidth: CGFloat = 30
    static let compactRectangleWidth: CGFloat = 10
    static let rectangleHeight: CGFloat = 10
    static let dotInternalPadding: CGFloat = 5
    static let circleDiameter: CGFloat = 6
}

private extension Double {
    static let colorFillOpacity: CGFloat = 0.4
}

extension VitalStatusBarView {
    enum Level: CaseIterable, Identifiable {
        var id: Self { self }

        case low
        case medium
        case high
        case optimal

        init(barLevel: VitalModel.Level) {
            switch barLevel {
            case .low: self = .low
            case .medium: self = .medium
            case .high: self = .high
            case .optimal: self = .optimal
            @unknown default: fatalError("Unhandled Case")
            }
        }

        var color: Color {
            switch self {
            case .low:
                    .vitalSevere
            case .medium:
                    .vitalWarning
            case .high:
                    .vitalGood
            case .optimal:
                    .vitalGreat
            }
        }
    }
}

struct VitalStatusBarView: View {
    let level: Level?
    let levelPercent: Double?

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Level.allCases) { levelCase in
                createRectangleShape(for: levelCase)
                    .frame(width: level == levelCase ? .expandedRectangleWidth : .compactRectangleWidth)
                    .overlay {
                        if level == levelCase, let clampedPercent {
                            HStack {
                                Circle()
                                    .fill(levelCase.color)
                                    .frame(square: .circleDiameter)
                                    .padding(.leading, ((.expandedRectangleWidth - 2 * .dotInternalPadding) * clampedPercent) - (.circleDiameter / 2))
                                    .transition(.scale)
                                Spacer(minLength: 0)
                            }
                            .frame(width: .expandedRectangleWidth - (2 * .dotInternalPadding))
                        }
                    }
            }
        }
        .frame(height: .rectangleHeight)
        .animation(.bouncy, value: level)
        .animation(.bouncy, value: levelPercent)
    }
}

private extension VitalStatusBarView {

    var clampedPercent: Double? {
        guard let levelPercent else { return nil }

        return max(min(1, levelPercent), 0)
    }

    func createRectangleShape(for level: Level) -> some View {
        RoundedRectangle(cornerRadius: .cornerRadius)
            .fill(level.color.opacity(.colorFillOpacity))
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadius)
                    .stroke(level.color)
            }
    }
}

#Preview {
    VStack {
        VitalStatusBarView(level: .low, levelPercent: 0.5)
        VitalStatusBarView(level: .medium, levelPercent: 0)
        VitalStatusBarView(level: .high, levelPercent: 1)
        VitalStatusBarView(level: .optimal, levelPercent: 0.75)
        VitalStatusBarView(level: nil, levelPercent: nil)
    }
}
