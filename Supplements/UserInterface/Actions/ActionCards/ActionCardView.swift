//
//  ActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import HealthKit
import SwiftData

struct ActionCardView<Content>: View where Content: View {
    let title: String
    let sampleTypes: Set<HKSampleType>
    let showSaveBar: Bool
    let saveHandler: (ModelContext) async -> Bool
    let content: (Bool, @escaping () -> Void) -> Content

    init(
        title: String,
        sampleTypes: Set<HKSampleType> = [],
        showSaveBar: Bool = true,
        saveHandler: @escaping (ModelContext) async -> Bool,
        @ViewBuilder content: @escaping (Bool, @escaping () -> Void) -> Content
    ) {
        self.title = title
        self.sampleTypes = sampleTypes
        self.showSaveBar = showSaveBar
        self.saveHandler = saveHandler
        self.content = content
    }

    @ObservedObject private var healthManager = HealthManager.shared

    @State private var triggerHealthPermissionSheet = false
    @State private var hasInserted = false
    @State private var didError = false
    @State private var error: Error?

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
                .sensoryFeedback(.error, trigger: didError)
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
                        .buttonStyle(.primary)
                        .sensoryFeedback(.success, trigger: hasInserted)
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(25)
        .animation(.easeInOut, value: hasInserted)
        .alert(error: $error)
        .healthDataAccessRequest(
            store: healthManager.healthStore,
            shareTypes: sampleTypes,
            readTypes: sampleTypes,
            trigger: triggerHealthPermissionSheet
        ) { result in
            switch result {
            case .success:
                handleSave()
            case .failure(let error):
                self.error = error
                self.didError.toggle()
            }
        }
    }
}

private extension ActionCardView {

    func handleSave() {
        Task {
            if sampleTypes.isNotEmpty {
                let authStatus = try await healthManager.checkAccess(
                    readTypes: Array(sampleTypes),
                    writeTypes: Array(sampleTypes)
                )

                if authStatus == .shouldRequest {
                    triggerHealthPermissionSheet.toggle()
                    return
                }
            }

            guard await saveHandler(modelContext) else { return }

            await MainActor.run {
                SoundPlayer.playLogHealthData()
                hasInserted = true
                Delay(1000) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ActionCardView(title: "Log Water") { (_) in
        return true
    } content: { (hasInserted, handleSave) in
        List {
            Text("Log Water")
        }
    }
    .tint(.blue)
}
