//
//  AskBudButton.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import SwiftUI

struct AskBudButton: View {

  var body: some View {
    Button {

    } label: {
      HStack {
        Image(.budPeek)
          .resizable()
          .frame(square: 30)

        Text("Chat with Bud")
          .font(.body)
          .bold()
          .fontDesign(.rounded)
      }
    }
    .buttonStyle(.secondary)
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        AskBudButton()
          .padding()
      }
      .horizontallyCentered()
    }
  }
}
