//
//  BioAgeTabView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-01-25.
//

import SwiftUI
import CoreHealth
import BloomUI
import AppUI

struct BioAgeTabView: View {
  @State private var provider = BiologicalAgeProvider.shared
  @State private var presentedSheet: AnyView?

  var body: some View {
    ZStack {
      BiologicalAgeMeter(
        chronologicalAge: provider.chronologicalAge,
        biologicalAge: provider.biologicalAge
      )

      updatedAtText
        .zStackAlignment(.bottom)
        .padding(.bottom, 20)
        .padding(.horizontal, 5)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 10)
    .padding(.bottom, -5)
    .ignoresSafeArea()
    .navigationBarTitleDisplayMode(.inline)
    .sheet($presentedSheet)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          presentedSheet = ActionsView(performDismiss: {
            presentedSheet = nil
          }).asAny
        } label: {
          Image(systemSymbol: .plus)
        }
      }
    }
    .task {
      provider.loadFromApplicationContext()
    }
  }
}

private extension BioAgeTabView {

  @ViewBuilder
  var updatedAtText: some View {
    Group {
      if let lastCalculated = provider.lastCalculated {
        Text("Updated \(lastCalculated, format: .relative(presentation: .named))")
      } else if provider.biologicalAge == nil {
        Text("Open Bloom on iPhone")
      }
    }
    .font(.caption2)
    .foregroundStyle(.secondary)
    .multilineTextAlignment(.center)
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      BioAgeTabView()
    }
  }
}
