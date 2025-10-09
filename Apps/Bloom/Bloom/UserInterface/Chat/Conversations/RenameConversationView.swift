//
//  RenameConversationView.swift
//  Bloom
//
//  Created by Assistant on 2025-10-09.
//

import SwiftUI
import DataContainer
import AppUI

struct RenameConversationView: View {
  let conversation: ChatConversation

  @State private var name: String
  @State private var error: Error?
  @FocusState private var isFocused: Bool

  @Environment(\.dismiss) private var dismiss

  init(conversation: ChatConversation) {
    self.conversation = conversation
    self._name = State(initialValue: conversation.name)
  }

  var body: some View {
    CardView {
      VStack {
        TextField(
          "Conversation Name",
          text: $name,
          prompt: Text("Conversation Name"),
          axis: .vertical
        )
        .focused($isFocused)
        .font(.title2)
        .fontDesign(.rounded)
        .bold()
        .multilineTextAlignment(.center)
        .textInputAutocapitalization(.words)
        .submitLabel(.done)
        .cardContainer()
        .onSubmit {
          Task {
            await save()
          }
        }

        AsyncButton {
          await save()
        } label: {
          Text("Save")
            .bold()
            .fontDesign(.rounded)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .padding()
    }
    .onAppear {
      isFocused = true
    }
    .alert(error: $error)
  }

  private func save() async {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmedName.isNotEmpty else { return }

    do {
      let conversationActor = ConversationModelActor(modelContainer: ContainerHolder.shared.container)
      _ = try await conversationActor.updateConversationName(
        conversationID: conversation.id,
        name: trimmedName
      )
      dismiss()
    } catch {
      self.error = error
    }
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      RenameConversationView(
        conversation: ChatConversation(
          id: "preview-id",
          name: "Test Conversation"
        )
      )
    }
  }
}
