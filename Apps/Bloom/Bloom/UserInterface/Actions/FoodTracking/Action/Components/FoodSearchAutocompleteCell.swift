//
//  FoodSearchAutocompleteCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-07.
//

import SFSafeSymbols
import SwiftUI

struct FoodSearchAutocompleteCell: View {
    let query: String

    var body: some View {
        HStack(spacing: 4) {
          Image(systemSymbol: .magnifyingglass)
            Text(query.capitalized)
        }
        .foregroundStyle(.tint)
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.tint.quinary)
        }
    }
}

#Preview {
    HStack {
        FoodSearchAutocompleteCell(query: "Apple")
        FoodSearchAutocompleteCell(query: "Apricot")
    }
}
