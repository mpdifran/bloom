//
//  ChatSettingsView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-18.
//

import SFSafeSymbols
import SwiftUI
import AppUI

struct ChatSettingsView: View {

  @State private var viewModel = ChatViewModel()

  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @State private var didDeleteChatHistory = false

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      BloomScrollView(showsChatBar: false) {
        VStack(spacing: 20) {
          resetSection
        }
        .padding()
      }
      .navigationTitle("Chat Settings")
      .navigationBarTitleDisplayMode(.inline)
      .confirmationDialog($confirmationDialogDetails)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
          .bold()
        }
      }
    }
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
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
            Label("Chat History Deleted", systemSymbol: .checkmark)
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
          ConfirmationDialogDetails.Button(title: "Delete", role: .destructive) {
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
          ConfirmationDialogDetails.Button(title: "Cancel", role: .cancel) {
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
