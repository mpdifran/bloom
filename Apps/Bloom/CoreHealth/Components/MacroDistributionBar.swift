//
//  MacroDistributionBar.swift
//  Bloom
//
//  Created by Assistant on 2025-06-10.
//

import SwiftUI
import BloomFoundation

public struct MacroDistributionBar: View {
  let proteinGrams: Double
  let carbsGrams: Double
  let fatGrams: Double
  let axis: Axis

  public init(proteinGrams: Double, carbsGrams: Double, fatGrams: Double, axis: Axis = .horizontal) {
    self.proteinGrams = proteinGrams
    self.carbsGrams = carbsGrams
    self.fatGrams = fatGrams
    self.axis = axis
  }
  
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
  
  public var body: some View {
    GeometryReader { proxy in
      if axis == .horizontal {
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
      } else {
        VStack(spacing: 0) {
          Rectangle()
            .fill(.protein)
            .frame(height: proxy.size.height * proteinPercent)

          Rectangle()
            .fill(.carbohydrates)
            .frame(height: proxy.size.height * carbohydratesPercent)

          Rectangle()
            .fill(.fat)
            .frame(height: proxy.size.height * fatPercent)
        }
      }
    }
    .frame(width: axis == .vertical ? 8 : nil, height: axis == .horizontal ? 8 : nil)
    .clipShape(Capsule())
  }
}

#Preview {
  HStack(spacing: 40) {
    // Horizontal bars
    VStack(spacing: 20) {
      Text("Horizontal")
        .font(.headline)

      MacroDistributionBar(
        proteinGrams: 30,
        carbsGrams: 50,
        fatGrams: 20,
        axis: .horizontal
      )

      MacroDistributionBar(
        proteinGrams: 20,
        carbsGrams: 40,
        fatGrams: 15,
        axis: .horizontal
      )

      MacroDistributionBar(
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
        axis: .horizontal
      )
    }
    .padding()

    // Vertical bars
    VStack(spacing: 20) {
      Text("Vertical")
        .font(.headline)

      HStack(spacing: 20) {
        MacroDistributionBar(
          proteinGrams: 30,
          carbsGrams: 50,
          fatGrams: 20,
          axis: .vertical
        )
        .frame(height: 150)

        MacroDistributionBar(
          proteinGrams: 20,
          carbsGrams: 40,
          fatGrams: 15,
          axis: .vertical
        )
        .frame(height: 150)

        MacroDistributionBar(
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
          axis: .vertical
        )
        .frame(height: 150)
      }
    }
    .padding()
  }
}
