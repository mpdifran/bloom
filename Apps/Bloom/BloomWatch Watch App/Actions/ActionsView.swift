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
        ActionCell(
          image: .logWeightIcon,
          title: "Weight",
          color: .mutedIndigo
        )
        .onTapGesture {
          presentedSheet = LogWeightView(performDismiss: {
            performDismiss?()
          }).asAny
        }

        ActionCell(
          image: .logWaterIcon,
          title: "Drink",
          color: .mutedBlue
        )
        .onTapGesture {
          presentedSheet = LogDrinkView(performDismiss: {
            performDismiss?()
          }).asAny
        }

        ActionCell(
          image: .logBowelIcon,
          title: "Bowel Movement",
          color: .brown
        )
        .onTapGesture {
          presentedSheet = LogBowelMovementView(performDismiss: {
            performDismiss?()
          }).asAny
        }

        ActionCell(
          image: .logBloodPressureIcon,
          title: "Blood Pressure",
          color: .mutedRed
        )
        .onTapGesture {
          presentedSheet = LogBloodPressureView(performDismiss: {
            performDismiss?()
          }).asAny
        }
      }
      .listStyle(.carousel)
      .navigationTitle("Actions")
    }
    .sheet($presentedSheet)
  }
}

#Preview {
  PreviewEnvironment {
    ActionsView(performDismiss: nil)
  }
}
