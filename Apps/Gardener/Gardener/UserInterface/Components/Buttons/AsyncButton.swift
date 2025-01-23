//
//  AsyncButton.swift
//  Gardener
//
//  Created by Mark DiFranco on 2025-01-23.
//


import SwiftUI
import AppUI

struct AsyncButton<Label: View>: View {
  let role: ButtonRole?
  let action: () async throws -> Void
  let label: () -> Label

  init(
    role: ButtonRole? = nil,
    action: @escaping () async throws -> Void,
    label: @escaping () -> Label
  ) {
    self.role = role
    self.action = action
    self.label = label
  }

  @State private var isLoading: Bool = false
  @State private var error: Error?

  var body: some View {
    Button(role: role) {
      guard !isLoading else { return }
      Task {
        isLoading = true
        do {
          try await action()
        } catch {
          self.error = error
        }
        isLoading = false
      }
    } label: {
      label()
        .opacity(isLoading ? 0 : 1)
        .overlay {
          if isLoading {
            CircularSpinnerView()
              .horizontallyCentered()
              .foregroundStyle(.tint)
          }
        }
    }
    .disabled(isLoading)
    .animation(.easeInOut, value: isLoading)
    .alert(error: $error)
  }
}

#Preview {
  AsyncButton {

  } label: {
    Text("Do Delay")
      .padding()
  }
  .tint(.blue)

  AsyncButton {
    throw NSError(description: "Sir, this is a preview.")
  } label: {
    Text("Throw Error")
      .padding()
  }
  .tint(.blue)
}
