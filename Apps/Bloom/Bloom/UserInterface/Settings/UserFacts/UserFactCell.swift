//
//  UserFactCell.swift
//  Bloom
//
//  Created by Claude on 2025-06-06.
//

import SwiftUI
import DataContainer
import BloomFoundation
import SFSafeSymbols

struct UserFactCell: View {
  let userFact: UserFactDTO
  let onDelete: () -> Void
  
  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(userFact.fact)
          .font(.headline)
          .bold()
          .fontDesign(.rounded)
          .fixedSize(horizontal: false, vertical: true)
          .multilineTextAlignment(.leading)

        Text("Revisit: \(userFact.revisitDate, format: .dateTime.day().month().year())")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Button(action: onDelete) {
        Image(systemSymbol: .trash)
          .foregroundStyle(.red)
      }
      .frame(square: 44)
      .buttonStyle(.plain)
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      UserFactCell(
        userFact: UserFactDTO(
          id: "1",
          fact: "I'm allergic to peanuts and tree nuts",
          dateAdded: Date().addingTimeInterval(-86400 * 30),
          revisitDate: Date().addingTimeInterval(86400 * 180)
        )
      ) {
        // Delete action
      }
      
      UserFactCell(
        userFact: UserFactDTO(
          id: "2", 
          fact: "I'm trying to gain muscle mass and prefer high-protein foods",
          dateAdded: Date().addingTimeInterval(-86400 * 7),
          revisitDate: Date().addingTimeInterval(86400 * 90)
        )
      ) {
        // Delete action
      }
    }
    .padding()
  }
}
