//
//  ActionsView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-26.
//

import SwiftUI
import AppUI
import BloomFoundation

struct ActionsView: View {
  let performDismiss: (() -> Void)?

  @State private var presentedSheet: AnyView?

  var body: some View {
    NavigationStack {
      List {
        HStack(spacing: 10) {
          Image(systemName: "scalemass")
            .font(.title2)
            .foregroundStyle(.mutedIndigo)
          Text("Weight")
            .font(.caption)
            .bold()
            .fontDesign(.rounded)
          Spacer()
        }
        .padding(.vertical, 10)
        .selectable()
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
