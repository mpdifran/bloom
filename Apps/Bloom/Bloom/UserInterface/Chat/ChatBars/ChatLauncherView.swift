//
//  ChatLauncherView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-22.
//

import SwiftUI

extension View {
  func chatLauncher() -> some View {
    modifier(ChatLauncherViewModifier())
  }
}

struct ChatLauncherViewModifier: ViewModifier {

  @Environment(TabController.self) private var tabController: TabController

  func body(content: Content) -> some View {
    content
      .overlay {
        ChatLauncherView()
          .readViewSize { proxy in
            tabController.chatLauncherSafeAreaInset = proxy.size.height
          }
          .zStackAlignment(.bottom)
      }
      .sheet(isPresented: Binding(
        get: { tabController.isShowingChat },
        set: { tabController.isShowingChat = $0 }
      )) {
        ChatView()
      }
  }
}

struct ChatLauncherView: View {

  @State private var presentedSheet: AnyView?
  @State private var selectionToggle = false

  @Environment(TabController.self) private var tabController: TabController

  var body: some View {
    HStack {
      tabPickerButton

      chatPlaceholder

      actionButton
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 40)
        .fill(.ultraThinMaterial)
        .ignoresSafeArea(edges: .bottom)
    }
    .sensoryFeedback(.selection, trigger: selectionToggle)
    .sheet($presentedSheet)
  }
}

private extension ChatLauncherView {

  var chatPlaceholder: some View {
    HStack {
      Image(systemSymbol: .sparkles)
        .foregroundStyle(.secondary)
      
      Text("Ask Bud")
        .foregroundStyle(.secondary)
      
      Spacer()
    }
    .frame(minWidth: 120)
    .padding(12)
    .cardContainer(fill: .background, includePadding: false)
    .onTapGesture {
      tabController.isShowingChat = true
      selectionToggle.toggle()
    }
  }

  var tabPickerButton: some View {
    Menu {
      ForEach(Tab.allCases.reversed()) { tab in
        Button {
          tabController.activeTab = tab
          selectionToggle.toggle()
        } label: {
          Label {
            Text(tab.name)
          } icon: {
            tab.tabImage
          }
        }
      }
    } label: {
      tabController.activeTab.tabImage
        .frame(square: 24)
        .padding(12)
        .cardContainer(fill: .background, includePadding: false)
    }
  }

  var actionButton: some View {
    Button {
      presentedSheet = ActionsView().asAny
      selectionToggle.toggle()
    } label: {
      Image(systemSymbol: .plus)
        .font(.title3)
        .fontDesign(.rounded)
        .fontWeight(.semibold)
        .frame(square: 24)
        .padding(12)
        .cardContainer(fill: .background, includePadding: false)
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ScrollView {
        VStack {
          ForEach(1...20, id: \.self) { number in
            Text("\(number)")
              .horizontalAlignment(.leading)
              .cardContainer()
          }
        }
        .padding()
      }
      .groupedBackground()
      .chatLauncher()
    }
  }
}
