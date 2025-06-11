//
//  MacroDistributionBar.swift
//  Bloom
//
//  Created by Assistant on 2025-06-10.
//

import SwiftUI
import BloomFoundation

struct MacroDistributionBar: View {
  let proteinGrams: Double
  let carbsGrams: Double
  let fatGrams: Double
  
  private var totalCalories: Double {
    (proteinGrams * .caloriesPerGramOfProtein) +
    (carbsGrams * .caloriesPerGramOfCarbs) +
    (fatGrams * .caloriesPerGramOfFat)
  }
  
  private var proteinPercent: Double {
    guard totalCalories > 0 else { return 0 }
    return (proteinGrams * .caloriesPerGramOfProtein) / totalCalories
  }
  
  private var carbohydratesPercent: Double {
    guard totalCalories > 0 else { return 0 }
    return (carbsGrams * .caloriesPerGramOfCarbs) / totalCalories
  }
  
  private var fatPercent: Double {
    guard totalCalories > 0 else { return 0 }
    return (fatGrams * .caloriesPerGramOfFat) / totalCalories
  }
  
  var body: some View {
    GeometryReader { proxy in
      HStack(spacing: 0) {
        Rectangle()
          .fill(.protein)
          .frame(width: proxy.size.width * proteinPercent)
        
        Rectangle()
          .fill(.carbohydrates)
          .frame(width: proxy.size.width * carbohydratesPercent)
        
        Rectangle()
          .fill(.fat)
          .frame(width: proxy.size.width * fatPercent)
      }
    }
    .frame(height: 8)
    .clipShape(Capsule())
  }
}

#Preview {
  VStack(spacing: 20) {
    MacroDistributionBar(
      proteinGrams: 30,
      carbsGrams: 50,
      fatGrams: 20
    )
    .padding(.horizontal)
    
    MacroDistributionBar(
      proteinGrams: 20,
      carbsGrams: 40,
      fatGrams: 15
    )
    .padding(.horizontal)
    
    MacroDistributionBar(
      proteinGrams: 0,
      carbsGrams: 0,
      fatGrams: 0
    )
    .padding(.horizontal)
  }
  .padding(.vertical)
}
