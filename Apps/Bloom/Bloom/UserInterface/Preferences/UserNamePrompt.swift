//
//  UserNamePrompt.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-05.
//

import SwiftUI
import CoreHealth
import BloomFoundation

struct UserNamePrompt: View {

    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared

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
                        TextField("", text: $healthManager.name, prompt: Text("Name"))
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
                    Task {
                        await Delay(300)

                        await MainActor.run {
                            onContinue()
                        }
                    }
                } label: {
                    Text("Continue")
                        .horizontallyCentered()
                }
                .buttonStyle(.primary)
                .disabled(healthManager.name.isEmpty)
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
