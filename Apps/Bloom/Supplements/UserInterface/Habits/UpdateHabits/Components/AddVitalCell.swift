//
//  AddVitalCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-16.
//

import SwiftUI

struct AddVitalCell: View {
    var body: some View {
      LabeledContent("Add Vital") {
        Image(systemName: "plus.app.fill")
          .foregroundStyle(.invertedText)
          .font(.title2)
          .bold()
      }
      .foregroundStyle(.invertedText)
      .selectable()
      .bold()
      .padding(.horizontal, 4)
      .cardContainer(fill: .tint, cornerRadius: 30)
    }
}

#Preview {
    AddVitalCell()
    .padding()
}
