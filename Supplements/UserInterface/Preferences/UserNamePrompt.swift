//
//  UserNamePrompt.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-05.
//

import SwiftUI

struct UserNamePrompt: View {

    let onContinue: () -> Void

    @AppStorage("PreferencesView.user.name") private(set) var userName: String = ""

    @State private var didContinue = false

    @Environment(\.dismiss) private var dismiss

    @FocusState private var isFocused

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                Text("Please enter your name")

                HStack {
                    LabeledContent("Name") {
                        TextField("", text: $userName, prompt: Text("Name"))
                            .multilineTextAlignment(.trailing)
                            .textContentType(.name)
                            .submitLabel(.done)
                            .focused($isFocused)
                    }
                }
                .multilineTextAlignment(.trailing)
                .cardContainer(fill: .background.secondary)
                .padding()

                Spacer()
            }
            .navigationTitle("Submit Feedback")
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
            .shelf {
                Button {
                    didContinue.toggle()
                    dismiss()
                    Delay(300) {
                        onContinue()
                    }
                } label: {
                    Text("Continue")
                        .horizontallyCentered()
                }
                .buttonStyle(.tertiary)
                .disabled(userName.isEmpty)
                .sensoryFeedback(.success, trigger: didContinue)
            }
        }
        .presentationDetents([.height(320)])
        .presentationCornerRadius(25)
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    struct PreviewView: View {

        @State private var showSheet = true

        var body: some View {
            Button {
                showSheet.toggle()
            } label: {
                Text("Show Sheet")
            }
            .sheet(isPresented: $showSheet) {
                UserNamePrompt { }
            }
        }
    }
    return PreviewView()

}
