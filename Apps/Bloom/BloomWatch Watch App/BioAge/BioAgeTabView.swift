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
  @Binding var showDetails: Bool
  @State private var resetController = NavigationResetController.shared

  var body: some View {
    ZStack {
      BiologicalAgeMeter(
        chronologicalAge: provider.chronologicalAge,
        biologicalAge: provider.displayBiologicalAge
      )
      .onTapGesture {
        if provider.displayBiologicalAge != nil {
          showDetails = true
        }
      }

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
    .onChange(of: resetController.resetTrigger) {
      presentedSheet = nil
      showDetails = false
    }
    .onChange(of: resetController.shouldShowBioAgeDetails) {
      if resetController.shouldShowBioAgeDetails && provider.biologicalAge != nil {
        showDetails = true
        resetController.shouldShowBioAgeDetails = false
      }
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
      BioAgeTabView(showDetails: .constant(false))
    }
  }
}
