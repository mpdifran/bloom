//
//  ActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import HealthKit
import SwiftData
import DataContainer

struct ActionCardView<Content>: View where Content: View {
  let title: String
  let detents: Set<PresentationDetent>
  let sampleTypes: Set<HKSampleType>
  let showSaveBar: Bool
  let performDismiss: (() -> Void)?
  let saveHandler: () async throws -> Bool
  let content: (Bool, @escaping () -> Void) -> Content

  init(
    title: String,
    detents: Set<PresentationDetent> = [.medium, .large],
    sampleTypes: Set<HKSampleType> = [],
    showSaveBar: Bool = true,
    performDismiss: (() -> Void)?,
    saveHandler: @escaping () async throws -> Bool,
    @ViewBuilder content: @escaping (Bool, @escaping () -> Void) -> Content
  ) {
    self.title = title
    self.detents = detents
    self.sampleTypes = sampleTypes
    self.showSaveBar = showSaveBar
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
    NavigationStack {
      content(hasInserted) { handleSave() }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(action: {
              dismiss()
            }, label: {
              Text("Cancel")
            })
          }
        }
        .sensoryFeedback(.error, trigger: didError)
        .if(showSaveBar) {
          $0.shelf {
            Button {
              handleSave()
            } label: {
              Group {
                if hasInserted {
                  Image(systemName: "checkmark")
                } else {
                  Text("Save")
                }
              }
              .horizontallyCentered()
            }
            .buttonStyle(.primary)
            .sensoryFeedback(.success, trigger: hasInserted)
          }
        }
    }
    .presentationDetents(detents)
    .presentationCornerRadius(25)
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
        MainTask {
          handleSave()
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

private extension ActionCardView {

  func handleSave() {
    Task {
      if sampleTypes.isNotEmpty {
        let authStatus = try await HealthPermissionChecker.shared.checkAccess(
          readTypes: Set(sampleTypes),
          writeTypes: Set(sampleTypes)
        )

        if authStatus == .shouldRequest {
          triggerHealthPermissionSheet.toggle()
          return
        }
      }

      do {
        guard try await saveHandler() else { return }
      } catch {
        self.error = error
      }

      await MainActor.run {
        SoundPlayer.playLogHealthData()
        hasInserted = true
        Delay(1000) {
          if let performDismiss {
            performDismiss()
          } else {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  ActionCardView(title: "Log Water", performDismiss: { }) {
    return true
  } content: { (hasInserted, handleSave) in
    List {
      Text("Log Water")
    }
  }
  .tint(.blue)
}
