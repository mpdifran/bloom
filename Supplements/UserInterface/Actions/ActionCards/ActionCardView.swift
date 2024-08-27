//
//  ActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import SwiftData

struct ActionCardView<Content>: View where Content: View {
    let title: String
    let showSaveBar: Bool
    let saveHandler: (ModelContext) -> Void
    let content: (Bool, @escaping () -> Void) -> Content

    init(
        title: String,
        showSaveBar: Bool = true,
        saveHandler: @escaping (ModelContext) -> Void,
        @ViewBuilder content: @escaping (Bool, @escaping () -> Void) -> Content
    ) {
        self.title = title
        self.showSaveBar = showSaveBar
        self.saveHandler = saveHandler
        self.content = content
    }

    @State private var hasInserted = false

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content(hasInserted) { handleSave() }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            dismiss()
                        }, label: {
                            Text("Cancel")
                        })
                    }
                }
                .if(showSaveBar) {
                    $0.shelf {
                        Button {
                            handleSave()
                        } label: {
                            Group {
                                if hasInserted {
                                    Image(systemName: "checkmark")
                                } else {
                                    Text("Save")
                                }
                            }
                            .horizontallyCentered()
                        }
                        .buttonStyle(.tertiary)
                        .sensoryFeedback(.success, trigger: hasInserted)
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(25)
        .animation(.easeInOut, value: hasInserted)
    }
}

private extension ActionCardView {

    func handleSave() {
        saveHandler(modelContext)

        SoundPlayer.playLogHealthData()
        hasInserted = true
        Delay(1000) {
            dismiss()
        }
    }
}

#Preview {
    ActionCardView(title: "Log Water") { _ in

    } content: { (hasInserted, handleSave) in
        List {
            Text("Log Water")
        }
    }
    .tint(.blue)
}
