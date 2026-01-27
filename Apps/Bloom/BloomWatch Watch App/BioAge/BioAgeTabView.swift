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
    VStack(spacing: 0) {
      BiologicalAgeMeter(
        chronologicalAge: provider.chronologicalAge,
        biologicalAge: provider.biologicalAge
      )
    }
    .navigationTitle("Bio Age")
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
      ToolbarItem(placement: .bottomBar) {
        if let lastCalculated = provider.lastCalculated {
          Text("Updated \(lastCalculated, format: .relative(presentation: .named))")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        } else if provider.biologicalAge == nil {
          Text("Open Bloom on iPhone")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
      }
    }
    .task {
      provider.loadFromApplicationContext()
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      BioAgeTabView()
    }
  }
}
