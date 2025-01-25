//
//  ThrowingUserTask.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-07.
//

import SwiftUI

func ThrowingUserTask(error errorBinding: Binding<Error?>, task: @Sendable @escaping () async throws -> Void) {
  Task {
    do {
      try await task()
    } catch {
      await MainActor.run {
        errorBinding.wrappedValue = error
      }
    }
  }
}
