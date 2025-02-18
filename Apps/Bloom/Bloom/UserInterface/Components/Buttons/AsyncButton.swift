//
//  AsyncButton.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-07.
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
    @ViewBuilder label: @escaping () -> Label
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
      VStack {
        label()
      }
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
    await Delay(1600)
  } label: {
    Text("Do Delay")
      .padding()
  }
  .tint(.mutedBlue)

  AsyncButton {
    await Delay(1600)
    throw NSError(description: "Sir, this is a preview.")
  } label: {
    Text("Throw Error")
      .padding()
  }
  .tint(.mutedBlue)
}
