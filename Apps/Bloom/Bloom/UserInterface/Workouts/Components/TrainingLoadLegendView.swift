//
//  TrainingLoadLegendView.swift
//  Bloom
//

import SwiftUI

struct TrainingLoadLegendView: View {

  var body: some View {
    CardView {
      LargeTitleActionCard("Training Load") {
        VStack(alignment: .leading, spacing: 16) {
          legendRow(
            title: "7-Day Average",
            description: "The line shows your rolling 7-day average training load."
          ) {
            RoundedRectangle(cornerRadius: 2)
              .fill(.text)
              .frame(width: 24, height: 3)
          }

          legendRow(
            title: "Well Above",
            description: "A significant spike in training load. This can increase your risk of injury."
          ) {
            RoundedRectangle(cornerRadius: 4)
              .strokeBorder(.blue.opacity(0.4), lineWidth: 1.5)
              .frame(width: 24, height: 16)
          }

          legendRow(
            title: "Above",
            description: "A moderate increase from your baseline, it can help move your steady zone up."
          ) {
            RoundedRectangle(cornerRadius: 4)
              .fill(.blue.opacity(0.6))
              .frame(width: 24, height: 16)
          }

          legendRow(
            title: "Steady",
            description: "Your baseline range. Training here means your load is consistent."
          ) {
            RoundedRectangle(cornerRadius: 4)
              .fill(.blue)
              .frame(width: 24, height: 16)
          }

          legendRow(
            title: "Below",
            description: "A moderate decrease from your baseline, it will bring your steady zone down."
          ) {
            RoundedRectangle(cornerRadius: 4)
              .fill(.blue.opacity(0.6))
              .frame(width: 24, height: 16)
          }

          legendRow(
            title: "Well Below",
            description: "A significant drop in training load. This may reduce fitness and health benefits."
          ) {
            RoundedRectangle(cornerRadius: 4)
              .strokeBorder(.blue.opacity(0.4), lineWidth: 1.5)
              .frame(width: 24, height: 16)
          }
        }
      }
    }
  }
}

private extension TrainingLoadLegendView {

  func legendRow<Swatch: View>(
    title: String,
    description: String,
    @ViewBuilder swatch: () -> Swatch
  ) -> some View {
    HStack(alignment: .top, spacing: 12) {
      swatch()
        .frame(width: 24, height: 24, alignment: .center)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.body)
          .bold()
          .fontDesign(.rounded)
          .fixedSize(horizontal: false, vertical: true)

        Text(description)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      TrainingLoadLegendView()
    }
  }
}
