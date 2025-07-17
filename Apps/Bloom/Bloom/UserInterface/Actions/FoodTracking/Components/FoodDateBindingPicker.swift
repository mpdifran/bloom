//
//  FoodDateBindingPicker.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-17.
//

import SwiftUI

struct FoodDateBindingPicker: View {
  @Binding var date: Date

  @State private var showDatePicker = false

  var body: some View {
    Button {
      showDatePicker.toggle()
    } label: {
      HStack(spacing: 2) {
        Text("\(date, formatter: DateFormatter.justRelativeDateMedium)")
        Image(systemSymbol: .chevronUpChevronDown)
          .font(.caption)
      }
      .bold()
      .padding(.vertical)
    }
    .popover(isPresented: $showDatePicker) {
      DatePicker(selection: $date, displayedComponents: .date) {
        Text("\(date, formatter: DateFormatter.justRelativeDateMedium)")
      }
      .datePickerStyle(.graphical)
      .frame(width: 300)
      .presentationCompactAdaptation(.popover)
    }
    .onChange(of: date) { _, _ in
      showDatePicker = false
    }
  }
}

#Preview {
  @Previewable @State var date = Date()

  NavigationStack {
    Text("Hello World")
      .toolbar {
        ToolbarItem(placement: .principal) {
          FoodDateBindingPicker(date: $date)
        }
      }
  }
}
