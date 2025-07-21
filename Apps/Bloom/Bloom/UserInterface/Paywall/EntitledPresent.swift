//
//  EntitledPresent.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-22.
//

import SwiftUI
import AppUI

@MainActor
func EntitledPresent<Content>(presentedSheet: Binding<AnyView?>, content: @escaping () -> Content) where Content: View {
  if EntitlementController.shared.hasBloomPro == true {
    presentedSheet.wrappedValue = content().asAny
  } else {
    presentedSheet.wrappedValue = BloomPlusPaywall {
      guard EntitlementController.shared.hasBloomPro == true else { return }

      Task {
        await Delay(300)
        presentedSheet.wrappedValue = content().asAny
      }
    }.asAny
  }
}

@MainActor
func EntitledAction(
  presentedSheet: Binding<AnyView?>,
  action: @escaping () -> Void
) {
  if EntitlementController.shared.hasBloomPro == true {
    action()
  } else {
    presentedSheet.wrappedValue = BloomPlusPaywall {
      guard EntitlementController.shared.hasBloomPro == true else { return }

      Task {
        await Delay(300)
        action()
      }
    }.asAny
  }
}
