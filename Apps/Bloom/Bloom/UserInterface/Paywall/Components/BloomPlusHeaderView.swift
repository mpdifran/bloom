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
  private let onDismiss: () -> Void

  init(showDismiss: Bool = true, onDismiss: @escaping () -> Void = { }) {
    self.showDismiss = showDismiss
    self.onDismiss = onDismiss
  }

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    HStack {
      Spacer()

      if showDismiss {
        Button {
          dismiss()
          onDismiss()
        } label: {
          Image(systemSymbol: .xmarkCircleFill)
            .foregroundStyle(.text, .regularMaterial)
            .font(.title)
        }
        .frame(square: 44)
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomPlusHeaderView()
  }
}
