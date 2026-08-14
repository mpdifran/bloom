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
    ZStack {
      HStack {
        Image(systemSymbol: .plusCircleFill)
          .foregroundStyle(.white, .tint)
          .font(.title)

        Text("Add Reminder")
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
      }
      VStack(alignment: .leading) {
        Text(verbatim: "1")
          .font(.title3)

        Text(verbatim: "1")
          .font(.subheadline)
      }
      .bold()
      .fontDesign(.rounded)
      .lineLimit(1)
      .opacity(0)
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      AddReminderCell()
    }
  }
}
