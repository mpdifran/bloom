//
//  FoodItemLogDatePicker.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-26.
//

import SFSafeSymbols
import SwiftUI
import CoreHealth

struct FoodItemLogDatePicker: View {

    @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared
    @State private var showDatePicker = false

    var body: some View {
        Button {
            showDatePicker.toggle()
        } label: {
            HStack(spacing: 2) {
                Text("\(nutritionViewModel.date, formatter: DateFormatter.justRelativeDateMedium)")
              Image(systemSymbol: .chevronUpChevronDown)
                    .font(.caption)
            }
            .bold()
            .padding(.vertical)
        }
        .popover(isPresented: $showDatePicker) {
            DatePicker(selection: $nutritionViewModel.date, displayedComponents: .date) {
                Text("\(nutritionViewModel.date, formatter: DateFormatter.justRelativeDateMedium)")
            }
            .datePickerStyle(.graphical)
            .frame(width: 300)
            .presentationCompactAdaptation(.popover)
        }
        .onChange(of: nutritionViewModel.date) { _, _ in
            showDatePicker = false
        }
    }
}

#Preview {
    NavigationStack {
        Text("Hello World")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    FoodItemLogDatePicker()
                }
            }
    }
}
