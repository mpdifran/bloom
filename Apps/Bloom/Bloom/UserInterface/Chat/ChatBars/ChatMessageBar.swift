//
//  ChatMessageBar.swift
//  Bloom
//
//  Created by Assistant on 2025-05-28.
//

import SwiftUI
import SFSafeSymbols
import AppUI

struct ChatMessageBar: View {
  
  @State private var text = ""
  @State private var image: UIImage?
  @State private var presentedSheet: AnyView?
  @State private var didSendToggle = false
  @State private var error: Error?
  
  @FocusState private var isFocused
  
  var body: some View {
    VStack {
      if image != nil {
        imageSection
      }
      
      HStack(alignment: .bottom) {
        ImagePicker(image: $image, presentedSheet: $presentedSheet) {
          Image(systemSymbol: .plusCircleFill)
            .foregroundStyle(.white, .tint)
            .font(.title)
            .frame(square: 24)
        }
        
        TextField(
          "",
          text: $text,
          prompt: Text("Message"),
          axis: .vertical
        )
        .focused($isFocused)
        .frame(minHeight: 24)
        .submitLabel(.send)
        .onSubmit {
          Task {
            await submit()
          }
        }
        .onChange(of: text) { oldValue, newValue in
          if let newLineIndex = newValue.lastIndex(of: "\n") {
            text.remove(at: newLineIndex)
            Task {
              await submit()
            }
          }
        }
        
        if text.isEmpty {
          Button {
            isFocused = false
          } label: {
            Image(systemSymbol: .chevronDownCircleFill)
              .foregroundStyle(.text, .fill)
              .font(.title)
              .frame(square: 24)
          }
        } else {
          Button {
            Task {
              await submit()
            }
          } label: {
            Image(systemSymbol: .arrowUpCircleFill)
              .foregroundStyle(.white, .tint)
              .font(.title)
              .frame(square: 24)
          }
        }
      }
      .padding(12)
      .cardContainer(fill: .background, includePadding: false)
    }
    .padding()
    .background {
      RoundedRectangle(cornerRadius: 40)
        .fill(.ultraThinMaterial)
        .ignoresSafeArea(edges: .bottom)
    }
    .animation(.bouncy, value: image)
    .sensoryFeedback(.impact, trigger: didSendToggle)
    .alert(error: $error)
    .sheet($presentedSheet)
    .onAppear {
      isFocused = true
    }
  }
}

private extension ChatMessageBar {
  
  var imageSection: some View {
    ScrollView(.horizontal) {
      HStack {
        if let image {
          EditableChatImageView(image: image) {
            self.image = nil
          }
          .transition(.scale)
        }
      }
      .padding(.horizontal)
    }
  }
  
  func submit() async {
    guard text.isNotEmpty || image != nil else { return }
    
    didSendToggle.toggle()
    
    let textToSend = text
    let imageToSend = image
    
    text = ""
    image = nil
    
    do {
      try await ChatController.shared.send(message: textToSend, image: imageToSend)
    } catch {
      self.error = error
    }
  }
}

#Preview {
  PreviewEnvironment {
    NavigationStack {
      ScrollView {
        VStack {
          ForEach(1...10, id: \.self) { number in
            HStack {
              Text("Message \(number)")
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
              Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
          }
        }
        .padding(.top)
      }
      .groupedBackground()
      .navigationTitle("Bud")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") { }
            .bold()
        }
        ToolbarItem(placement: .primaryAction) {
          Button { } label: {
            Label("Settings", systemSymbol: .gear)
          }
        }
      }
      .safeAreaInset(edge: .bottom) {
        ChatMessageBar()
      }
    }
  }
}
