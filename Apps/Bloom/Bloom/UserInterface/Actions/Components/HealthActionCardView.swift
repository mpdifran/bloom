//
//  HealthActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-17.
//

import SwiftUI
import SFSafeSymbols
import AppUI
import HealthKit
import CoreHealth
import BloomFoundation

struct HealthActionCardView<Content>: View where Content: View {
  let sampleTypes: Set<HKSampleType>
  let showSaveBar: Bool
  let addPaddingToSaveButton: Bool
  let performDismiss: (() -> Void)?
  let saveHandler: () async throws -> Bool
  let content: (Bool, @escaping () -> Void) -> Content

  init(
    sampleTypes: Set<HKSampleType> = [],
    showSaveBar: Bool = true,
    addPaddingToSaveButton: Bool = false,
    performDismiss: (() -> Void)? = nil,
    saveHandler: @escaping () async throws -> Bool,
    @ViewBuilder content: @escaping (Bool, @escaping () -> Void) -> Content
  ) {
    self.sampleTypes = sampleTypes
    self.showSaveBar = showSaveBar
    self.addPaddingToSaveButton = addPaddingToSaveButton
    self.performDismiss = performDismiss
    self.saveHandler = saveHandler
    self.content = content
  }

  @ObservedObject private var healthManager = HealthManager.shared

  @State private var triggerHealthPermissionSheet = false
  @State private var hasInserted = false
  @State private var didError = false
  @State private var error: Error?

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack {
      VStack {
        content(hasInserted) {
          Task {
            await performSave()
          }
        }
      }

      if showSaveBar {
        AsyncButton {
          if await handleSave() {
            // We throw this on a separate task to make sure the async button completes first, and stops showing the loading indicator.
            Task {
              await onSaveSuccess()
            }
          }
        } label: {
          Group {
            if hasInserted {
              Image(systemSymbol: .checkmark)
            } else {
              Text("Save")
            }
          }
          .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .sensoryFeedback(.success, trigger: hasInserted)
        .if(addPaddingToSaveButton) {
          $0.padding(.horizontal)
        }
        .padding(.top)
      }
    }
    .sensoryFeedback(.error, trigger: didError)
    .animation(.easeInOut, value: hasInserted)
    .alert(error: $error)
    .healthDataAccessRequest(
      store: healthManager.healthStore,
      shareTypes: sampleTypes,
      readTypes: sampleTypes,
      trigger: triggerHealthPermissionSheet
    ) { result in
      switch result {
      case .success:
        Task {
          await performSave()
        }
      case .failure(let error):
        MainTask {
          self.error = error
          self.didError.toggle()
        }
      }
    }
  }
}

private extension HealthActionCardView {

  func performSave() async {
    guard await handleSave() else { return }

    await onSaveSuccess()
  }

  func handleSave() async -> Bool {
    do {
      if sampleTypes.isNotEmpty {
        let authStatus = try await HealthPermissionChecker.shared.checkAccess(
          readTypes: Set(sampleTypes),
          writeTypes: Set(sampleTypes)
        )

        if authStatus == .shouldRequest {
          triggerHealthPermissionSheet.toggle()
          return false
        }
      }

      guard try await saveHandler() else { return false }

      return true
    } catch {
      self.didError = true
      self.error = error
    }
    return false
  }

  func onSaveSuccess() async {
    await MainActor.run {
      SoundPlayer.playLogHealthData()
      hasInserted = true
    }
    await Delay(1000)
    await MainActor.run {
      onDismiss()
    }
  }

  func onDismiss() {
    if let performDismiss {
      performDismiss()
    } else {
      dismiss()
    }
  }
}

#Preview {
  PreviewSheetPresent {
    CardView {
      HealthActionCardView() {
        // Perform save
        return true
      } content: { (hasInserted, performSave) in
        VStack {
          if hasInserted {
            Text("Water Logged")
          } else {
            Text("Log Water")
              .selectable()
              .onTapGesture {
                performSave()
              }
          }
        }
      }
      .padding()
    }
  }
}
