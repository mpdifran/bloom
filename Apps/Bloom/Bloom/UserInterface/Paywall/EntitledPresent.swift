//
//  EntitledPresent.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-22.
//

import SwiftUI
import AppUI
import BloomFoundation

@MainActor
func EntitledPresent<Content>(presentedSheet: Binding<AnyView?>, content: @escaping () -> Content) where Content: View {
  if EntitlementController.shared.hasBloomPro == true {
    presentedSheet.wrappedValue = content().asAny
  } else {
    presentedSheet.wrappedValue = BloomPlusPaywall(onDismiss: {
      guard EntitlementController.shared.hasBloomPro == true else { return }

      Task {
        await Delay(300)

        presentedSheet.wrappedValue = WelcomeToBloomPlusView {
          Task {
            await Delay(300)
            presentedSheet.wrappedValue = content().asAny
          }
        }.asAny
      }

    }).asAny
  }
}

@MainActor
func EntitledAction(
  presentedSheet: Binding<AnyView?>,
  focus: BloomPlusPaywall.Focus = .standard,
  action: @escaping () -> Void
) {
  if EntitlementController.shared.hasBloomPro == true {
    action()
  } else {
    presentedSheet.wrappedValue = BloomPlusPaywall(focus: focus, onDismiss: {
      guard EntitlementController.shared.hasBloomPro == true else { return }

      Task {
        await Delay(300)
        await MainActor.run {
          presentedSheet.wrappedValue = WelcomeToBloomPlusView {
            Task {
              await Delay(300)
              action()
            }
          }.asAny
        }
      }
    }).asAny
  }
}

@MainActor
func AsyncEntitledAction(
  presentedSheet: Binding<AnyView?>,
  focus: BloomPlusPaywall.Focus = .standard,
  action: @escaping () async -> Void
) async {
  if EntitlementController.shared.hasBloomPro == true {
    await action()
  } else {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      presentedSheet.wrappedValue = BloomPlusPaywall(focus: focus, onDismiss: {
        guard EntitlementController.shared.hasBloomPro == true else {
          continuation.resume()
          return
        }

        Task {
          await Delay(300)
          await withCheckedContinuation { (welcomeContinuation: CheckedContinuation<Void, Never>) in
            presentedSheet.wrappedValue = WelcomeToBloomPlusView {
              welcomeContinuation.resume()
            }.asAny
          }

          await Delay(300)
          await action()
          continuation.resume()
        }
      }).asAny
    }
  }
}
