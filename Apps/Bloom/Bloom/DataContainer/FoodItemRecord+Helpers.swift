//
//  FoodItemRecord+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import DataContainer
import BloomModel

extension FoodItemRecord {

  convenience init(foodItem: FoodItem) {
    self.init(
      id: foodItem.id.value,
      name: foodItem.name,
      brandName: foodItem.brandName ?? "",
      flavour: foodItem.flavour ?? "",
      rawCountry: foodItem.country?.rawValue,
      calories: foodItem.calories?.doubleValue(for: .largeCalorie()) ?? 0,
      protein: foodItem.protein?.doubleValue(for: .gram()) ?? 0,
      carbohydrates: foodItem.carbohydrates?.doubleValue(for: .gram()) ?? 0,
      fat: foodItem.fat?.doubleValue(for: .gram()) ?? 0,
      saturatedFat: foodItem.saturatedFat?.doubleValue(for: .gram()),
      transFat: foodItem.transFat?.doubleValue(for: .gram()),
      polyunsaturatedFat: foodItem.polyunsaturatedFat?.doubleValue(for: .gram()),
      monounsaturatedFat: foodItem.monounsaturatedFat?.doubleValue(for: .gram()),
      fiber: foodItem.fiber?.doubleValue(for: .gram()),
      sugar: foodItem.sugar?.doubleValue(for: .gram()),
      cholesterol: foodItem.cholesterol?.doubleValue(for: .gramUnit(with: .milli)),
      sodium: foodItem.sodium?.doubleValue(for: .gramUnit(with: .milli)),
      calcium: foodItem.calcium?.doubleValue(for: .gramUnit(with: .milli)),
      iron: foodItem.iron?.doubleValue(for: .gramUnit(with: .milli)),
      potassium: foodItem.potassium?.doubleValue(for: .gramUnit(with: .milli)),
      magnesium: foodItem.magnesium?.doubleValue(for: .gramUnit(with: .milli)),
      zinc: foodItem.zinc?.doubleValue(for: .gramUnit(with: .milli)),
      vitaminA: foodItem.vitaminA?.doubleValue(for: .gramUnit(with: .milli)),
      vitaminB6: foodItem.vitaminB6?.doubleValue(for: .gramUnit(with: .milli)),
      vitaminB12: foodItem.vitaminB12?.doubleValue(for: .gramUnit(with: .milli)),
      vitaminC: foodItem.vitaminC?.doubleValue(for: .gramUnit(with: .milli)),
      vitaminD: foodItem.vitaminD?.doubleValue(for: .gramUnit(with: .milli)),
      vitaminE: foodItem.vitaminE?.doubleValue(for: .gramUnit(with: .milli)),
      servingName: foodItem.servingName,
      servingUnitString: foodItem.servingQuantity?.unit,
      servingValue: foodItem.servingQuantity?.value,
      ingredients: foodItem.ingredients,
      category: Category(rawValue: foodItem.category.rawValue),
      isVerified: foodItem.isVerified
    )
  }

  func apply(foodItem: FoodItem) -> Bool {
    var didChange = false

    if self.id != foodItem.id.value {
      self.id = foodItem.id.value
      didChange = true
    }
    if self.name != foodItem.name {
      self.name = foodItem.name
      didChange = true
    }
    if self.brandName != foodItem.brandName ?? "" {
      self.brandName = foodItem.brandName ?? ""
      didChange = true
    }
    if self.flavour != foodItem.flavour ?? "" {
      self.flavour = foodItem.flavour ?? ""
      didChange = true
    }
    if self.rawCountry != foodItem.country?.rawValue {
      self.rawCountry = foodItem.country?.rawValue
      didChange = true
    }
    if self.calories != foodItem.calories?.doubleValue(for: .largeCalorie()) ?? 0 {
      self.calories = foodItem.calories?.doubleValue(for: .largeCalorie()) ?? 0
      didChange = true
    }
    if self.protein != foodItem.protein?.doubleValue(for: .gram()) ?? 0 {
      self.protein = foodItem.protein?.doubleValue(for: .gram()) ?? 0
      didChange = true
    }
    if self.carbohydrates != foodItem.carbohydrates?.doubleValue(for: .gram()) ?? 0 {
      self.carbohydrates = foodItem.carbohydrates?.doubleValue(for: .gram()) ?? 0
      didChange = true
    }
    if self.fat != foodItem.fat?.doubleValue(for: .gram()) ?? 0 {
      self.fat = foodItem.fat?.doubleValue(for: .gram()) ?? 0
      didChange = true
    }
    if self.saturatedFat != foodItem.saturatedFat?.doubleValue(for: .gram()) {
      self.saturatedFat = foodItem.saturatedFat?.doubleValue(for: .gram())
      didChange = true
    }
    if self.transFat != foodItem.transFat?.doubleValue(for: .gram()) {
      self.transFat = foodItem.transFat?.doubleValue(for: .gram())
      didChange = true
    }
    if self.polyunsaturatedFat != foodItem.polyunsaturatedFat?.doubleValue(for: .gram()) {
      self.polyunsaturatedFat = foodItem.polyunsaturatedFat?.doubleValue(for: .gram())
      didChange = true
    }
    if self.monounsaturatedFat != foodItem.monounsaturatedFat?.doubleValue(for: .gram()) {
      self.monounsaturatedFat = foodItem.monounsaturatedFat?.doubleValue(for: .gram())
      didChange = true
    }
    if self.fiber != foodItem.fiber?.doubleValue(for: .gram()) {
      self.fiber = foodItem.fiber?.doubleValue(for: .gram())
      didChange = true
    }
    if self.sugar != foodItem.sugar?.doubleValue(for: .gram()) {
      self.sugar = foodItem.sugar?.doubleValue(for: .gram())
      didChange = true
    }
    if self.cholesterol != foodItem.cholesterol?.doubleValue(for: .gramUnit(with: .milli)) {
      self.cholesterol = foodItem.cholesterol?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.sodium != foodItem.sodium?.doubleValue(for: .gramUnit(with: .milli)) {
      self.sodium = foodItem.sodium?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.calcium != foodItem.calcium?.doubleValue(for: .gramUnit(with: .milli)) {
      self.calcium = foodItem.calcium?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.iron != foodItem.iron?.doubleValue(for: .gramUnit(with: .milli)) {
      self.iron = foodItem.iron?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.potassium != foodItem.potassium?.doubleValue(for: .gramUnit(with: .milli)) {
      self.potassium = foodItem.potassium?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.magnesium != foodItem.magnesium?.doubleValue(for: .gramUnit(with: .milli)) {
      self.magnesium = foodItem.magnesium?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.zinc != foodItem.zinc?.doubleValue(for: .gramUnit(with: .milli)) {
      self.zinc = foodItem.zinc?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.vitaminA != foodItem.vitaminA?.doubleValue(for: .gramUnit(with: .milli)) {
      self.vitaminA = foodItem.vitaminA?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.vitaminB6 != foodItem.vitaminB6?.doubleValue(for: .gramUnit(with: .milli)) {
      self.vitaminB6 = foodItem.vitaminB6?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.vitaminB12 != foodItem.vitaminB12?.doubleValue(for: .gramUnit(with: .milli)) {
      self.vitaminB12 = foodItem.vitaminB12?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.vitaminC != foodItem.vitaminC?.doubleValue(for: .gramUnit(with: .milli)) {
      self.vitaminC = foodItem.vitaminC?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.vitaminD != foodItem.vitaminD?.doubleValue(for: .gramUnit(with: .milli)) {
      self.vitaminD = foodItem.vitaminD?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.vitaminE != foodItem.vitaminE?.doubleValue(for: .gramUnit(with: .milli)) {
      self.vitaminE = foodItem.vitaminE?.doubleValue(for: .gramUnit(with: .milli))
      didChange = true
    }
    if self.servingName != foodItem.servingName {
      self.servingName = foodItem.servingName
      didChange = true
    }
    if self.servingUnitString != foodItem.servingQuantity?.unit {
      self.servingUnitString = foodItem.servingQuantity?.unit
      didChange = true
    }
    if self.servingValue != foodItem.servingQuantity?.value {
      self.servingValue = foodItem.servingQuantity?.value
      didChange = true
    }
    if self.ingredients != foodItem.ingredients {
      self.ingredients = foodItem.ingredients
      didChange = true
    }
    if self.category?.rawValue != foodItem.category.rawValue {
      self.category = Category(rawValue: foodItem.category.rawValue)
      didChange = true
    }
    if self.isVerified != foodItem.isVerified {
      self.isVerified = foodItem.isVerified
      didChange = true
    }

    return didChange
  }
}

extension FoodItemRecord {

  func asNetworkFoodItem() -> FoodItem {
    let quantity: FoodItem.Quantity?
    if let servingValue, let servingUnitString {
      quantity = FoodItem.Quantity(
        value: servingValue,
        unit: servingUnitString
      )
    } else {
      quantity = nil
    }

    return FoodItem(
      id: FoodItemIdentifier(id),
      name: name,
      brandName: brandName,
      flavour: flavour,
      country: FoodItem.Country(rawValue: rawCountry ?? ""),
      calories: FoodItem.Quantity(value: calories, unit: "Cal"),
      protein: FoodItem.Quantity(value: protein, unit: "g"),
      carbohydrates: FoodItem.Quantity(value: carbohydrates, unit: "g"),
      fat: FoodItem.Quantity(value: fat, unit: "g"),
      saturatedFat: saturatedFat.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      transFat: transFat.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      polyunsaturatedFat: polyunsaturatedFat.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      monounsaturatedFat: monounsaturatedFat.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      fiber: fiber.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      sugar: sugar.map({ FoodItem.Quantity(value: $0, unit: "g") }),
      cholesterol: cholesterol.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      sodium: sodium.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      calcium: calcium.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      iron: iron.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      potassium: potassium.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      magnesium: magnesium.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      zinc: zinc.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminA: vitaminA.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminB6: vitaminB6.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminB12: vitaminB12.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminC: vitaminC.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminD: vitaminD.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      vitaminE: vitaminE.map({ FoodItem.Quantity(value: $0, unit: "mg") }),
      servingName: servingName,
      servingQuantity: quantity,
      ingredients: ingredients,
      category: networkCategory,
      isVerified: isVerified
    )
  }

  var networkCategory: FoodItem.Category {
    guard let dbCategory = self.category else { return .generic }

    return FoodItem.Category(rawValue: dbCategory.rawValue) ?? .generic
  }

  func logDates() -> [Date] {
    servings?.compactMap({ $0.foodItemLog?.date }) ?? []
  }
}
