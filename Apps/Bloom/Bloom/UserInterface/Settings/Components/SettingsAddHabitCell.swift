//
//  SettingsAddHabitCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-23.
//

import SFSafeSymbols
import SwiftUI

struct SettingsAddHabitCell: View {
  var body: some View {
    Label("Add a habit", systemSymbol: .plus)
      .bold()
      .fontDesign(.rounded)
      .horizontallyCentered()
      .cardContainer()
  }
}

#Preview {
  ScrollView {
    VStack {
      SettingsAddHabitCell()
    }
    .padding()
  }
  .groupedBackground()
}
