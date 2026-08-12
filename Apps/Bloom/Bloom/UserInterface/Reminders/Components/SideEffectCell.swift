import SwiftUI
import DataContainer
import BloomFoundation
import SFSafeSymbols
import HealthKit
import CoreHealth

struct SideEffectCell: View {
  let sideEffect: ReminderSideEffect
  
  var body: some View {
    HStack {
      Image(systemSymbol: icon)
        .foregroundStyle(.secondary)
        .frame(width: 24)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.body)
          .fontWeight(.medium)
        
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      Image(systemSymbol: .chevronRight)
        .foregroundStyle(.tertiary)
        .font(.caption)
    }
  }
  
  private var icon: SFSymbol {
    switch sideEffect.type {
    case .logFood:
      return .forkKnife
    case .logWater:
      return .waterbottle
    @unknown default:
      return .questionmark
    }
  }
  
  private var title: String {
    switch sideEffect.type {
    case .logFood:
      return String(localized: "Log Food")
    case .logWater:
      return String(localized: "Log Water")
    @unknown default:
      return String(localized: "Unknown Action")
    }
  }
  
  private var subtitle: String {
    switch sideEffect.type {
    case .logFood:
      if let config = sideEffect.decodeConfiguration(as: LogFoodSideEffectConfig.self) {
        let mealName = config.meal.name
        return "\(config.foodItemName) • \(config.servingSize.format()) serving • \(mealName)"
      }
      return String(localized: "Configure food item")
      
    case .logWater:
      if let config = sideEffect.decodeConfiguration(as: LogWaterSideEffectConfig.self) {
        let unit = HKUnit(from: config.unitString)
        let quantity = HKQuantity(unit: unit, doubleValue: config.amount)
        return quantity.displayString(for: unit)
      }
      return String(localized: "Configure water amount")
    @unknown default:
      return String(localized: "Unknown configuration")
    }
  }
  
}

#Preview {
  PreviewEnvironment {
    VStack {
      SideEffectCell(sideEffect: ReminderSideEffect.Preview.logVitamins)
      
      Divider()
      
      SideEffectCell(sideEffect: ReminderSideEffect.Preview.logWater16oz)
    }
    .cardContainer()
  }
}
