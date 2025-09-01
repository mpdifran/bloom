//
//  AddReminderCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-01.
//

import SwiftUI
import SFSafeSymbols

struct AddReminderCell: View {
  var body: some View {
    HStack {
      Image(systemSymbol: .plusCircleFill)
        .foregroundStyle(.white, .tint)
        .font(.title)

      Text("Add Reminder")
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
    }
    .cardContainer()
  }
}

#Preview {
  AddReminderCell()
}
