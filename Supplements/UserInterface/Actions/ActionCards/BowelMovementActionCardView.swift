//
//  BowelMovementActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import SwiftData

struct BowelMovementActionCardView: View {
    @State private var date = Date.now
    @State private var stoolType: Int = 1
    @State private var duration: BowelMovement.Duration = .between5And10Min

    @State private var hasInserted = false

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Stool Type", selection: $stoolType) {
                        ForEach(1...7, id: \.self) { stoolType in
                            Text("Type \(stoolType)")
                                .tag(stoolType)
                        }
                    }
                    Picker("Duration", selection: $duration) {
                        ForEach(BowelMovement.Duration.allCases) { duration in
                            Text(duration.name)
                                .tag(duration)
                        }
                    }
                }

                Section {
                    DatePicker("Time", selection: $date)
                }
            }
            .navigationTitle("New Bowel Movement")
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
                    logEntry()
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
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(25)
        .tint(.brown)
    }
}

private extension BowelMovementActionCardView {

    func logEntry() {
        let model = BowelMovement(
            date: date,
            bristolStoolType: stoolType,
            duration: duration
        )

        modelContext.insert(model)

        hasInserted = true
        Delay(1000) {
            dismiss()
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
                BowelMovementActionCardView()
            }
        }
    }
    return PreviewView()
}
