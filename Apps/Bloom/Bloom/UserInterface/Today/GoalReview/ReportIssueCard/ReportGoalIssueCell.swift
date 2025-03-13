//
//  ReportGoalIssueCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-13.
//

import SwiftUI

struct ReportGoalIssueCell: View {
  let title: String
  let isSelected: Bool

  var body: some View {
    HStack {
      Text(title)

      Spacer()

      if isSelected {
        Image(systemSymbol: .checkmark)
          .foregroundStyle(.tint)
      }
    }
    .bold()
    .fontDesign(.rounded)
    .cardContainer()
    .selectable()
  }
}

#Preview {
  VStack {
    ReportGoalIssueCell(title: "No Goals Present", isSelected: true)
    ReportGoalIssueCell(title: "Goal(s) too Low", isSelected: false)
  }
  .padding()
  .groupedBackground()
  .tint(.mutedYellow)
}
