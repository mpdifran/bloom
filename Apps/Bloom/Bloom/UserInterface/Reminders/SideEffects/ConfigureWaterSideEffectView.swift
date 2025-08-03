import SwiftUI
import DataContainer
import BloomFoundation
import SFSafeSymbols
import HealthKit
import CoreHealth

struct ConfigureWaterSideEffectView: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable private var unitPreferences = HealthUnitPreferences.shared

  @State private var waterAmount: String = ""
  @State private var selectedUnit: HKUnit
  @State private var presetToggle = false

  let existingSideEffect: ReminderSideEffect?
  let onSave: (ReminderSideEffect) -> Void

  // Preset amounts based on the selected unit
  private var presetAmounts: [Double] {
    if selectedUnit == .literUnit(with: .milli) {
      return [250, 500, 750, 1000] // ml
    } else if selectedUnit == .fluidOunceImperial() {
      return [8, 16, 24, 32] // imperial oz
    } else {
      return [8, 16, 24, 32] // US oz
    }
  }

  // Computed property for creating HKQuantity with selected unit
  private func waterQuantity(for amount: Double) -> HKQuantity {
    HKQuantity(unit: selectedUnit, doubleValue: amount)
  }

  init(
    existingSideEffect: ReminderSideEffect? = nil,
    onSave: @escaping (ReminderSideEffect) -> Void
  ) {
    self.existingSideEffect = existingSideEffect
    self.onSave = onSave
    
    // Initialize selected unit from user preferences
    let userUnit = HealthUnitPreferences.shared.liquidVolumeUnit
    _selectedUnit = State(initialValue: userUnit)

    // Initialize state from existing side effect
    if
      let existingSideEffect = existingSideEffect,
      let config = existingSideEffect.decodeConfiguration(as: LogWaterSideEffectConfig.self)
    {
      let storedUnit = HKUnit(from: config.unitString)

      // Convert to user's preferred unit if different
      let amount: Double
      if storedUnit == userUnit {
        amount = config.amount
      } else {
        let quantity = HKQuantity(unit: storedUnit, doubleValue: config.amount)
        amount = quantity.doubleValue(for: userUnit)
      }

      _waterAmount = State(initialValue: amount.format())
    } else {
      // Set default water amount based on unit
      let defaultAmount: Double
      if userUnit == .literUnit(with: .milli) {
        defaultAmount = 250 // 250 ml
      } else {
        defaultAmount = 8 // 8 oz
      }
      _waterAmount = State(initialValue: defaultAmount.format())
    }
  }

  var body: some View {
    NavigationStack {
      BloomScrollView {
        VStack {
          amountSection
          presetSection
        }
      }
      .navigationTitle(existingSideEffect == nil ? "Log Water" : "Log Water")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .animation(.bouncy, value: waterAmount)
      .shelf {
        Button {
          saveAction()
        } label: {
          Text("Save")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .disabled(waterAmount.isEmpty)
      }
    }
  }
}

private extension ConfigureWaterSideEffectView {

  var amountSection: some View {
    VStack {
      LabeledContent("Amount") {
        TextField("Amount", text: $waterAmount)
          .keyboardType(.decimalPad)
          .multilineTextAlignment(.trailing)
          .textFieldStyle(.roundedBorder)
          .frame(maxWidth: 120)

        LocalizedUnitPickerView(unit: $selectedUnit)
          .onChange(of: selectedUnit) { oldUnit, newUnit in
            // Convert amounts when unit changes
            if oldUnit != newUnit {
              convertAmounts(from: oldUnit, to: newUnit)
            }
          }
      }
      .cardContainer()
    }
  }

  var presetSection: some View {
    VStack {
      SectionTitleView("Presets")
        .padding(.horizontal)
      
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        ForEach(presetAmounts, id: \.self) { amount in
          ZStack {
            Text(waterQuantity(for: amount).displayString(for: selectedUnit))
              .font(.title2)
              .fontWeight(.black)
              .fontDesign(.rounded)
              .foregroundStyle(.tint)
              .zStackAlignment(.bottomTrailing)
          }
          .aspectRatio(1.5, contentMode: .fit)
          .cardContainer(
            fill: .tint.tertiary,
            stroke: Double(waterAmount) == amount ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.clear),
            lineWidth: 8
          )
          .sensoryFeedback(.impact, trigger: presetToggle)
          .onTapGesture {
            waterAmount = amount.format()
            presetToggle.toggle()
          }
        }
      }
    }
    .tint(.mutedBlue)
  }
  
  func convertAmounts(from oldUnit: HKUnit, to newUnit: HKUnit) {
    // Convert water amount if it has a value
    if let currentValue = Double(waterAmount), currentValue > 0 {
      let quantity = HKQuantity(unit: oldUnit, doubleValue: currentValue)
      waterAmount = quantity.doubleValue(for: newUnit).format()
    }
  }
  
  func saveAction() {
    guard let amount = Double(waterAmount), amount > 0 else { return }
    
    let sideEffect = ReminderSideEffect.logWater(
      amount: amount,
      unit: selectedUnit
    )
    
    if let existingSideEffect = existingSideEffect {
      sideEffect.id = existingSideEffect.id
    }
    
    onSave(sideEffect)
  }
}

#Preview {
  PreviewEnvironment {
    ConfigureWaterSideEffectView { sideEffect in
      print("Saved: \(sideEffect)")
    }
  }
}
