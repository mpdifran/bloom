//
//  ChatLauncherTabAccessoryView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-09-10.
//

import SwiftUI
import AppUI

struct ChatLauncherTabAccessoryView: View {

  @Binding var presentedSheet: AnyView?

  var body: some View {
    HStack {
      Image(.budPeek)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(square: 34)
        .foregroundStyle(.secondary)

      Text("Ask Bud")
        .foregroundStyle(.secondary)

      Spacer(minLength: 0)

      Button {
        presentedSheet = ActionsView().asAny
      } label: {
        Image(systemSymbol: .plus)
          .foregroundStyle(.white, .tint)
          .font(.body)
          .bold()
          .fontDesign(.rounded)
          .fontWeight(.semibold)
          .frame(width: 40, height: 26)
          .padding(4)
          .background {
            Capsule()
              .fill(.tint)
          }
      }
    }
    .selectable()
    .padding(.horizontal, 8)
    .sheet($presentedSheet)
  }
}

#Preview {
  @Previewable @State var presentedSheet: AnyView?

  if #available(iOS 26.0, *) {
    PreviewEnvironment {
      TabView {
        Text("A")
          .tabItem {
            Label("A", systemSymbol: .document)
          }
        Text("B")
          .tabItem {
            Label("B", systemSymbol: .documentOnDocument)
          }
      }
      .sheet($presentedSheet)
      .tabViewBottomAccessory {
        ChatLauncherTabAccessoryView(presentedSheet: $presentedSheet)
      }
    }
  }
}
