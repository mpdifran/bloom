//
//  ChatSettingsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-18.
//

import SwiftUI
import AppUI

struct ChatSettingsView: View {

  @State private var viewModel = ChatViewModel.shared

  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @State private var didDeleteChatHistory = false

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        resetSection
      }
      .padding()
    }
    .groupedBackground()
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .confirmationDialog($confirmationDialogDetails)
  }
}

private extension ChatSettingsView {

  var resetSection: some View {
    VStack {
      SectionTitleView("Chat History")
        .padding(.horizontal)

      SettingsSectionContainer {
        Group {
          if didDeleteChatHistory {
            Label("Chat History Deleted", systemImage: "checkmark")
              .bold()
              .horizontallyCentered()
              .frame(minHeight: 60)
              .foregroundStyle(.mutedGreen)
          } else {
            AsyncButton(role: .destructive) {
              try await confirmDeleteChatHistory()
            } label: {
              Text("Delete Chat History")
                .bold()
                .horizontallyCentered()
                .frame(minHeight: 60)
            }
          }
        }
        .tint(.mutedRed)
      }
    }
  }

  func confirmDeleteChatHistory() async throws {
    try await withCheckedThrowingContinuation { continuation in
      confirmationDialogDetails = ConfirmationDialogDetails(
        title: "Are You Sure?",
        message: "This can't be undone. Your entire chat history will be deleted.",
        buttons: [
          .init(title: "Delete", role: .destructive) {
            Task {
              do {
                try await viewModel.deleteChatHistory()
                didDeleteChatHistory = true
                continuation.resume()
              } catch {
                continuation.resume(throwing: error)
              }
            }
          },
          .init(title: "Cancel", role: .cancel) {
            continuation.resume()
          }
        ]
      )
    }
  }
}

#Preview {
  PreviewSheetPresent {
    ChatSettingsView()
  }
}
