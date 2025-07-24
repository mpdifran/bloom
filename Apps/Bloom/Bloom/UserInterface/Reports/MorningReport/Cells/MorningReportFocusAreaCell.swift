//
//  MorningReportFocusAreaCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-24.
//

import SwiftUI

struct MorningReportFocusAreaCell: View {
  let focusArea: String

  var body: some View {
    VStack(spacing: 30) {
      VStack(spacing: 10) {
        Image(systemSymbol: .heartTextClipboardFill)
          .foregroundStyle(.white, .tint.secondary)
          .font(.system(size: 40))

        Text("Today's Focus")
          .font(.title2)
          .bold()
      }

      Text(focusArea)
        .font(.body)
        .fixedSize(horizontal: false, vertical: true)
    }
    .horizontallyCentered()
    .fontDesign(.rounded)
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MorningReportFocusAreaCell(
        focusArea: "You had too much sodium yesterday. Try and keep your sodium intake below 2300 mg today!"
      )
    }
  }
}
