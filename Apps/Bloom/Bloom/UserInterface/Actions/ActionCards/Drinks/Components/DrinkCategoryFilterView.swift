//
//  DrinkCategoryFilterView.swift
//  Bloom
//
//  Created by Claude on 2026-01-23.
//

import SwiftUI
import SFSafeSymbols
import BloomFoundation

struct DrinkCategoryFilterView: View {
  @Binding var selectedCategory: DrinkCategory?

  var body: some View {
    ScrollViewReader { scrollReader in
      ScrollView(.horizontal) {
        HStack(spacing: 8) {
          // "All" chip
          CategoryChip(
            title: "All",
            symbol: nil,
            isSelected: selectedCategory == nil
          )
          .id("All")
          .onTapGesture {
            selectedCategory = nil
            withAnimation {
              scrollReader.scrollTo("All", anchor: .center)
            }
          }

          // Category chips
          ForEach(DrinkCategory.allCases.filter { $0 != .custom }, id: \.self) { category in
            CategoryChip(
              title: category.displayName,
              symbol: category.symbol,
              isSelected: selectedCategory == category
            )
            .id(category.rawValue)
            .onTapGesture {
              selectedCategory = category
              withAnimation {
                scrollReader.scrollTo(category.rawValue, anchor: .center)
              }
            }
          }
        }
        .padding(.horizontal)
      }
      .onAppear {
        if let category = selectedCategory {
          scrollReader.scrollTo(category.rawValue, anchor: .center)
        }
      }
    }
    .scrollIndicators(.hidden)
    .animation(.easeInOut, value: selectedCategory)
    .sensoryFeedback(.selection, trigger: selectedCategory)
  }
}

// MARK: - Category Chip

private struct CategoryChip: View {
  let title: String
  let symbol: SFSymbol?
  let isSelected: Bool

  var body: some View {
    HStack(spacing: 6) {
      if let symbol {
        Image(systemSymbol: symbol)
          .font(.subheadline)
      }
      Text(title)
        .font(.subheadline)
        .fontWeight(.semibold)
    }
    .foregroundStyle(isSelected ? .white : .primary)
    .padding(.horizontal, 16)
    .frame(minHeight: 36)
    .background {
      Capsule()
        .fill(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill))
    }
    .selectable()
  }
}

// MARK: - Category Symbols

private extension DrinkCategory {
  var symbol: SFSymbol? {
    switch self {
    case .water:
      .drop
    case .coffee:
      .cupAndSaucerFill
    case .tea:
      .leafFill
    case .milk:
      .cupAndSaucerFill
    case .soft:
      .bubblesAndSparkles
    case .alcohol:
      .wineglassFill
    case .custom:
      .plusCircle
    }
  }
}

#Preview {
  @Previewable @State var selectedCategory: DrinkCategory?

  VStack {
    DrinkCategoryFilterView(selectedCategory: $selectedCategory)
      .tint(.blue)

    Text("Selected: \(selectedCategory?.displayName ?? "All")")
      .padding()
  }
}
