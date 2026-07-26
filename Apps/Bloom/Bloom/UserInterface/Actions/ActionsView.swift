//
//  ActionsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import CoreHealth

struct ActionsView: View {

  @State private var presentedCardSheet: AnyView?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    CardView {
      LargeTitleActionCard("Actions") {
        ActionsList(presentedCardSheet: $presentedCardSheet, onDismiss: { dismiss() })
      }
    }
    .sheet($presentedCardSheet)
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      ActionsView()
    }
  }
}
