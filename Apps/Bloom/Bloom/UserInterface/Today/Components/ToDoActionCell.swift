//
//  ToDoActionCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-06.
//

import SFSafeSymbols
import SwiftUI
import DataContainer

struct ToDoActionCell: View {
    let title: String
    let subtitle: String
    let symbol: SFSymbol
    let isComplete: Bool
    let vitalKind: VitalModel.Kind?
    let useSecondaryBackground: Bool

    init(
        title: String,
        subtitle: String,
        symbol: SFSymbol,
        isComplete: Bool,
        vitalKind: VitalModel.Kind?,
        useSecondaryBackground: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.isComplete = isComplete
        self.vitalKind = vitalKind
        self.useSecondaryBackground = useSecondaryBackground
    }

    var body: some View {
        HStack {
            CompletionCheckmarkView(
                state: isComplete ? .metGoal : .unmetGoal,
                colorize: true
            )

            LabeledContent {
                Image(systemSymbol: symbol)
                    .foregroundStyle(.tint)
            } label: {
                VStack(alignment: .leading) {
                    Text(title)

                    HStack(spacing: 2) {
                        if let vitalKind {
                            Text(vitalKind.name)
                            Text(verbatim: "•")
                        }
                        Text(subtitle)
                        Spacer(minLength: 0)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .bold()

            Spacer()
        }
        .cardContainer(fill: useSecondaryBackground ? AnyShapeStyle(.background.secondary) : AnyShapeStyle(.background))
    }
}

#Preview {
    ScrollView {
        VStack {
            ToDoActionCell(
                title: "Log Weight",
                subtitle: "Daily",
                symbol: .gaugeWithDotsNeedleBottom50percentBadgePlus,
                isComplete: false,
                vitalKind: nil
            )
            .tint(.mutedIndigo)
            ToDoActionCell(
                title: "Log Weight",
                subtitle: "Daily",
                symbol: .gaugeWithDotsNeedleBottom50percentBadgePlus,
                isComplete: true,
                vitalKind: .nutrition
            )
            .tint(.mutedBlue)
        }
        .horizontallyCentered()
        .padding()
    }
}
