//
//  TitleDatePicker.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-11.
//

import SwiftUI

struct TitleDatePicker: View {
    @Binding var date: Date

    @State private var showDatePicker = false

    var body: some View {
        HStack {
            Text("\(date, formatter: DateFormatter.justRelativeDateMedium)")
            Image(systemName: "chevron.down")
                .font(.caption)
        }
        .contentShape(Rectangle())
        .bold()
        .onTapGesture {
            showDatePicker.toggle()
        }
        .popover(isPresented: $showDatePicker) {
            DatePicker(selection: $date, in: ...Date.now, displayedComponents: .date) {
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
    NavigationStack {
        Text("Hello World")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    TitleDatePicker(date: .constant(.now))
                }
            }
    }
}
