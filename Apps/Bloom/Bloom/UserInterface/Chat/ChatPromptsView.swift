//
//  ChatPromptsView.swift
//  Bloom
//
//  Created by Zach Radford on 2025-05-09.
//

import SwiftUI
import AppUI
import SFSafeSymbols

struct ChatPromptsView: View {

  @State private var error: Error?

  private let prompts = [
    "How can I improve my heart health?",
    "What is my sleep quality score?",
    "Track my water intake for today",
    "Suggest a workout for my fitness level",
    "Log my weight",
    "How's my nutrition doing?",
    "Help me manage stress"
  ]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(prompts, id: \.self) { prompt in
          PromptCard(message: prompt) {
            Task {
              await sendMessage(prompt)
            }
          }
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 10)
    }
    .alert(error: $error)
  }

  private func sendMessage(_ message: String) async {
    do {
      try await ChatController.shared.send(
        message: message,
        images: [],
        chatContexts: [],
        conversationID: nil,
        lastMessageID: nil
      )
    } catch {
      self.error = error
    }
  }
}

private struct PromptCard: View {
  let message: String
  let action: () -> Void
  
  @State private var isPressed = false
  
  var body: some View {
    Button(action: action) {
      Text(message)
        .font(.subheadline)
        .fontWeight(.medium)
        .multilineTextAlignment(.leading)
        .lineLimit(2)
        .frame(width: 180, height: 44, alignment: .leading)
    }
    .cardContainer()
    .scaleEffect(isPressed ? 0.97 : 1.0)
    .buttonStyle(.plain)
    .sensoryFeedback(.selection, trigger: isPressed)
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in isPressed = true }
        .onEnded { _ in 
          isPressed = false
        }
    )
  }
}

#Preview {
  ChatPromptsView()
}
