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

        Text("Ask Bud")
          .font(.body)
          .foregroundStyle(.tint)
          .bold()
          .fontDesign(.rounded)
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 16)
      .background {
        Capsule()
          .fill(.tint.tertiary)
      }
    }
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
