//
//  BloomPlusHeaderView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-08.
//

import SFSafeSymbols
import SwiftUI

struct BloomPlusHeaderView: View {

  private let showDismiss: Bool

  init(showDismiss: Bool = true) {
    self.showDismiss = showDismiss
  }

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    HStack {
      Spacer()

      if showDismiss {
        Button {
          dismiss()
        } label: {
          Image(systemSymbol: .xmarkCircleFill)
            .foregroundStyle(.white, .gray)
            .font(.title)
        }
        .frame(square: 44)
      }
    }
  }
}

#Preview {
  BloomPlusHeaderView()
}
