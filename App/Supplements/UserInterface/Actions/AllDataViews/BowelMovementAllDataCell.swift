//
//  BowelMovementAllDataCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import Charts
import SwiftData
import DataContainer

struct BowelMovementAllDataCell: View {

    @Query var bowelMovements: [BowelMovement]

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("Bowel Movements")
                        .font(.title3)
                        .bold()

                    Spacer()

                    DisclosureIndicator()
                }

                chart
            }
            Spacer()
        }
        .frame(height: 180)
        .cardContainer(fill: .background.secondary)
    }
}

private extension BowelMovementAllDataCell {

    var collatedBowelMovements: [[BowelMovement]] {
        bowelMovements.group { lhs, rhs in
            Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date)
        }
    }

    var chart: some View {
        Chart {
            ForEach(collatedBowelMovements, id: \.self) { movements in
                if let firstDate = movements.first?.date {
                    BarMark(
                        x: .value("Date", Calendar.current.startOfDay(for: firstDate)),
                        y: .value("Count", movements.count)
                    )
                    .foregroundStyle(.brown)
                }
            }
        }
        .chartXScale(numDaysToNow: 30)
    }
}

#Preview {
    ScrollView {
        VStack {
            BowelMovementAllDataCell()
        }
        .padding()
    }
}
