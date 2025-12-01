//
//  HealthCategoryToggleCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-01.
//

import SwiftUI
import BloomUI

struct HealthCategoryToggleCell: View {
  let category: AIHealthCategory
  @Binding var isEnabled: Bool

  var body: some View {
    Toggle(isOn: $isEnabled) {
      HStack {
        RoundedRectangle(cornerRadius: 17)
          .fill(category.color)
          .frame(square: 45)
          .overlay {
            Image(systemSymbol: category.icon)
              .font(.title2)
              .foregroundStyle(.white)
          }

        VStack(alignment: .leading, spacing: 4) {
          Text(category.displayName)
            .font(.body)
            .fontDesign(.rounded)
            .bold()

          Text(category.description)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
    .padding(.vertical, 8)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HealthCategoryToggleCell(category: .physicalActivity, isEnabled: .constant(true))
      HealthCategoryToggleCell(category: .demographics, isEnabled: .constant(false))
    }
  }
}
