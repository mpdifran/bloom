//
//  ChatBar.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-01.
//

import SwiftUI

private extension Double {
    static let animationSpeed: Double = 1.5
}

struct ChatBar: View {
    @Binding var text: String
    let onSubmit: () -> Void

    @State private var gradientColors: [Color] = [.pink, .indigo, .purple]

    @FocusState private var isTextFieldFocused: Bool

    let timer = Timer.publish(every: .animationSpeed, tolerance: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .bottom) {
            TextField(
                "",
                text: $text,
                prompt: Text("Chat with Bloom").foregroundStyle(.primary),
                axis: .vertical
            )
            .focused($isTextFieldFocused)
            .onSubmit(onSubmit)
            .submitLabel(.send)
            .padding(.horizontal, 10)
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.thickMaterial)
                    .padding(2)
                    .background {
                        RoundedRectangle(cornerRadius: 27)
                            .fill(
                                AngularGradient(
                                    colors: computedGradientColors,
                                    center: .center,
                                    angle: .degrees(0)
                                )
                            )
                    }
            }
            
            Button {
                isTextFieldFocused = false
                onSubmit()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.thickMaterial)
                    .background {
                        Circle()
                        .fill(
                            AngularGradient(
                                colors: computedGradientColors,
                                center: .center,
                                angle: .degrees(0)
                            )
                        )
                    }
            }
            .buttonStyle(.plain)
        }
        .animation(.linear(duration: .animationSpeed), value: gradientColors)
        .onReceive(timer) { (_) in
            shiftGradientColors()
        }
        .onChange(of: text) { oldValue, newValue in
            if let newLineIndex = newValue.lastIndex(of: "\n") {
                text.remove(at: newLineIndex)
                isTextFieldFocused = false
                onSubmit()
            }
        }
    }
}

private extension ChatBar {

    var computedGradientColors: [Color] {
        let first = gradientColors.first!
        return gradientColors + [first]
    }

    func shiftGradientColors() {
        let last = gradientColors.removeLast()
        gradientColors.insert(last, at: 0)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            VStack {
                ChatBubbleCell(message: "Hello World, it's me!", isDirect: false, isCurrentUser: false, showTail: true)
                ChatBubbleCell(message: "Oh, ok, sounds good.", isDirect: false, isCurrentUser: true, showTail: true)
                ChatBubbleCell(message: "What does that mean?", isDirect: false, isCurrentUser: false, showTail: true)
                ChatBubbleCell(message: "Huh?", isDirect: false, isCurrentUser: false, showTail: true)
                ChatBubbleCell(message: "You know what it means.", isDirect: false, isCurrentUser: true, showTail: true)
            }
        }
        .groupedBackground()
        .navigationTitle("Preview")
        .safeAreaInset(edge: .bottom) {
            ChatBar(text: .constant("This is a message"), onSubmit: { })
                .padding()
        }
    }
}
