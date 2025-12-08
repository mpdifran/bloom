//
//  AIDataShareIcon.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-08.
//

import SwiftUI

struct AIDataShareIcon: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 13)
      .fill(.mutedPink)
      .frame(square: 44)
      .overlay {
        Image(systemSymbol: .heartFill)
          .foregroundStyle(.white)
          .font(.title2)
          .bold()
      }
  }
}

#Preview {
  AIDataShareIcon()
}
