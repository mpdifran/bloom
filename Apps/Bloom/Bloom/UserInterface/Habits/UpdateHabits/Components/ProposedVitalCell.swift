//
//  ProposedVitalCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-04.
//

import SwiftUI
import DataContainer

struct ProposedVitalCell: View {
  let vital: VitalModel
  let changeVital: () -> Void
  let removeVital: () -> Void

  var body: some View {
    VStack(alignment: .leading) {
      MiniVitalCell(vital: vital, useSecondaryBackground: false)

      Button {
        changeVital()
      } label: {
        LabeledContent("Change Vital") {
          Image(systemName: "arrow.trianglehead.clockwise.heart.fill")
            .foregroundStyle(.white)
            .font(.title2)
            .bold()
        }
        .foregroundStyle(.white)
        .bold()
        .padding()
        .contentShape(Rectangle())
      }

      Divider()
        .padding(.horizontal)

      Button {
        removeVital()
      } label: {
        LabeledContent("Remove Vital") {
          Image(systemName: "xmark.app.fill")
            .foregroundStyle(.white)
            .font(.title2)
            .bold()
        }
        .foregroundStyle(.white)
        .bold()
        .padding()
        .contentShape(Rectangle())
      }
    }
    .padding(4)
    .cardContainer(fill: .tint, includePadding: false, cornerRadius: 30)
    .tint(vital.color)
  }
}

#Preview {
  ScrollView {
    VStack {
      ProposedVitalCell(
        vital: VitalModel(
          id: .nutrition,
          subtitle: nil,
          status: "Unhealthy",
          color: .vitalWarning,
          barLevel: VitalModel.BarLevel(level: .medium, proportion: 0.4),
          hasNoData: false
        )
      ) {

      } removeVital: {

      }

      ProposedVitalCell(
        vital: VitalModel(
          id: .sleepQuality,
          subtitle: nil,
          status: "Poor",
          color: .vitalSevere,
          barLevel: VitalModel.BarLevel(level: .low, proportion: 0.8),
          hasNoData: false
        )
      ) {

      } removeVital: {
        
      }
    }
    .padding()
  }
}
