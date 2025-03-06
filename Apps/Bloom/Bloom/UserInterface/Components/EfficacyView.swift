//
//  EfficacyView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SFSafeSymbols
import SwiftUI

struct EfficacyView: View {
  let efficacy: Int

  var body: some View {
    switch efficacy {
    case 2, 3:
      Image(systemSymbol: .checkmarkSquareFill)
        .foregroundStyle(.blue)
        .imageScale(.large)
    case 4, 5:
      Image(systemSymbol: .checkmarkSealFill)
        .foregroundStyle(.green)
        .imageScale(.large)
    default:
      Image(systemSymbol: .checkmarkCircleFill)
        .foregroundStyle(.orange)
        .imageScale(.large)

    }
  }
}

#Preview {
  VStack {
    EfficacyView(efficacy: 1)
    EfficacyView(efficacy: 3)
    EfficacyView(efficacy: 5)
  }
}
