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

    var body: some View {
        ActionCardView(title: "New Bowel Movement") { modelContext in
            let model = BowelMovement(
                date: date,
                bristolStoolType: stoolType,
                duration: duration
            )
            modelContext.insert(model)
            return true
        } content: { (_, _) in
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
        }
        .tint(.brown)
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
