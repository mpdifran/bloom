//
//  ActionsView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-26.
//

import SwiftUI
import AppUI
import BloomFoundation
import CoreHealth

struct ActionsView: View {
  let performDismiss: (() -> Void)?

  @State private var presentedSheet: AnyView?

  var body: some View {
    NavigationStack {
      List {
        ActionCell(image: .logWeightIcon, title: "Weight")
          .onTapGesture {
            presentedSheet = LogWeightView(performDismiss: {
              performDismiss?()
            }).asAny
          }
      }
      .listStyle(.carousel)
      .navigationTitle("Log")
    }
    .sheet($presentedSheet)
  }
}

#Preview {
  PreviewEnvironment {
    ActionsView(performDismiss: nil)
  }
}
