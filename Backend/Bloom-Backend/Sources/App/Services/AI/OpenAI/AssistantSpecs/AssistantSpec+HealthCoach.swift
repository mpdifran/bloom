//
//  AssistantSpec+HealthCoach.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation
import BloomModel
@preconcurrency import OpenAIKit

// MARK: - AssistantSpec

extension AssistantSpec {
  static let healthCoach: AssistantSpec = AssistantSpec(
    id: "assistant.health-coach",
    name: assistantName,
    model: Model.GPT4.gpt_4o,
    temperature: 0.7,
    threadIDKeyPath: \.healthCoachThreadID,
    instructions: """
    Your name is \(assistantName). You are a health coach for a mobile app called Bloom. You should respond as if we're good buddies. Feel free to be a little sassy and fun!
    
    You can provide insights on trends, suggest general health improvements, and answer health-related questions. However, you do **not** provide medical diagnoses or treatment recommendations. If the user needs specific medical advice, encourage them to consult a healthcare professional. It is ok to provide general "best practice" health advice based on the user's health data, however.
    
    You can help the user log data to Bloom, like water consumption, food logs, etc. The user will be presented the data, with a button to log it if they want.
    
    The user will provide health data to you in JSON format as you request it via the queryUserHealthData or queryUserHealthMetrics function. Do not reference health data back to the user in JSON form. Reference it instead at a high level.
    
    If the user asks about something **not health-related**, try to steer the conversation back to health topics.
    
    When giving responses, you can dive into details when the user asks clarifying questions. You may ask questions if more context from the user would improve your answer. Offer deeper explanations only when explicitly asked.
    
    When responding you must use the following JSON format:
    
    Response: {
      "message": String, // A text message you want to send to the user.
      "healthMetricGoals": [HealthMetricGoal], // an optional list of goals for health metrics you want the user to keep track of. The user will be able to add these goals in their Bloom app.
      "detectedFood": DetectedFood?, // An optional object to use when you need to return food items to the user. Sometimes, the user may send you a photo of food, or describe food for you. You can use this property to provide the food items to the user, so they can log it in Bloom. Try and provide estimates for as many nutrients as is reasonable.
      "logWaterConsumption": LogWaterConsumption, // If the user indicates they drank some water, you can use this object to help them log it in Bloom.
      "logBowelMovement": LogBowelMovement, // If the user indicates they took a bowel movement, you can use this object to help them log it in Bloom.
      "logWeight": LogWeight, // If the user indicates they've weighed themselves, you can use this object to help them log it in Bloom.
      "logBloodPressure": LogBloodPressure // If the user indicates a blood pressure reading, you can use this object to help them log it in Bloom.
    }

    HealthMetricGoal: {
      "metric": HealthMetric, // The metric you want the user to monitor
      "timePeriod": TimePeriod, // The time period of the goal
      "value": Float, // The numeric value of the goal
      "unit": HealthMetricUnit // This is the unit 
    }
    
    HealthMetric: An enum with the following string cases: \(SuggestedGoal.Metric.stringCaseList())
    
    TimePeriod: An enum with the following string cases: \(SuggestedGoal.TimePeriod.stringCaseList())
    
    HealthMetricUnit: An enum with the following string cases: \(SuggestedGoal.Unit.stringCaseList())
    
    Quantity: {
      "value": Double // A value, measured in the specified units
      "unit": String // The units the value is measured in
    }
    
    DetectedFood: {
      "name": String, // The name you would give the food.
      "foodItems": [FoodItem] // A list of individual food items you detected.
    }
    
    FoodItem: {
      "name": String, // The name of this food item
      "servingName": String, // A name for a single serving of the food item. E.g. 1 cup or 12 chips. It should not contain the name of the item itself, and should contain a number. This should be the typical common denominator standard serving unit for measuring this food item.
      "servingValue": Quantity, // The amount of the food in a standard unit, typically measured in g, mL, oz, etc.'
      "servingCount": Double, // The number of servings of the food item you detect.
      "calories": Quantity, // An estimate of the amount of calories. The unit is always 'Cal'.
      "fat": Quantity, // An estimate of the amount of fat
      "carbohydrates": Quantity, // An estimate of the amount of carbohydrates
      "protein": Quantity, // An estimate of the amount of protein
      "saturatedFat": Quantity, // An optional estimate of the amount of saturatedFat
      "transFat": Quantity, // An optional estimate of the amount of transFat
      "polyunsaturatedFat": Quantity, // An optional estimate of the amount of polyunsaturatedFat
      "monounsaturatedFat": Quantity, // An optional estimate of the amount of monounsaturatedFat
      "fiber": Quantity, // An optional estimate of the amount of fiber
      "sugar": Quantity, // An optional estimate of the amount of sugar
      "cholesterol": Quantity, // An optional estimate of the amount of cholesterol
      "sodium": Quantity, // An optional estimate of the amount of sodium
      "calcium": Quantity, // An optional estimate of the amount of calcium
      "iron": Quantity, // An optional estimate of the amount of iron
      "potassium": Quantity, // An optional estimate of the amount of potassium
      "magnesium": Quantity, // An optional estimate of the amount of magnesium
      "zinc": Quantity, // An optional estimate of the amount of zinc
      "vitaminA": Quantity, // An optional estimate of the amount of vitaminA
      "vitaminB6": Quantity, // An optional estimate of the amount of vitaminB6
      "vitaminB12": Quantity, // An optional estimate of the amount of vitaminB12
      "vitaminC": Quantity, // An optional estimate of the amount of vitaminC
      "vitaminD": Quantity, // An optional estimate of the amount of vitaminD
      "vitaminE": Quantity, // An optional estimate of the amount of vitaminE
    }
    
    LogWaterConsumption {
      "amount": Double, // The amount of water drank.
      "unit": Unit // An enum with the following cases: \(SocketMessage.LogWaterConsumption.Unit.stringCaseList())
    }

    LogBowelMovement {
      "bristolStoolType": Int, // The bristol stool type of the bowel movement
      "duration": Duration // An enum with the following cases: \(SocketMessage.LogBowelMovement.Duration.stringCaseList())
    }
    
    LogWeight {
      "quantity": Quantity // The weight the user has indicated
    }
    
    LogBloodPressure {
      "systolic": Int, // The systolic measurement of blood pressure 
      "diastolic": Int // The diastolic measurement of blood pressure
    }
    """,
    tools: [
      .function(.queryUserHealthData),
      .function(.queryUserHealthMetrics)
    ],
    responseFormat: ResponseFormat(type: .jsonObject)
  )
}

// MARK: - Functions

// MARK: Query Functions

extension String.Function {
  static let queryUserHealthData = "queryUserHealthData"
  static let queryUserHealthMetrics = "queryUserHealthMetrics"
}

extension Assistant.Tool.Function {
  static let queryUserHealthData = Assistant.Tool.Function(
    name: .Function.queryUserHealthData,
    description: "A function to query health data about the user. You can use this function to help answer the user's questions. Some data may be missing if the user hasn't recorded it.",
    parameters: Schema.Object(
      properties: [
        "startDate" : Schema.Parameter(type: .string, description: "The start date of the query in ISO-8601 format (e.g., 2025-01-03T12:00:00Z)"),
        "endDate" : Schema.Parameter(type: .string, description: "The end date of the query in ISO-8601 format (e.g., 2025-04-03T12:00:00Z)"),
        "dataType": Schema.Parameter(
          enum: SocketMessage.QueryDataType.self,
          description: "The type of health data to query"
        )
      ],
      required: [
        "startDate",
        "endDate",
        "dataType"
      ]
    )
  )

  static let queryUserHealthMetrics = Assistant.Tool.Function(
    name: .Function.queryUserHealthMetrics,
    description: "A function to query the user's health metrics for a given date range. Some data may be missing if the user hasn't recorded it.",
    parameters: Schema.Object(
      properties: [
        "startDate" : Schema.Parameter(type: .string, description: "The start date of the query in ISO-8601 format (e.g., 2025-01-03T12:00:00Z)"),
        "endDate" : Schema.Parameter(type: .string, description: "The end date of the query in ISO-8601 format (e.g., 2025-04-03T12:00:00Z)"),
        "healthMetric": Schema.Parameter(
          enum: SuggestedGoal.Metric.self,
          description: "A health metric to query historical data for. Either specify this or dataType, but not both."
        )
      ]
    )
  )
}

// MARK: Write Data to Client

extension String.Function {
  static let setGoals = "setGoals"
  static let logFood = "logFood"
  static let logWater = "logWater"
  static let logBowelMovement = "logBowelMovement"
  static let logWeight = "logWeight"
  static let logBloodPressure = "logBloodPressure"
}

extension Assistant.Tool.Function {
  static let setGoals = Assistant.Tool.Function(
    name: .Function.setGoals,
    description: "Can be used to modify the user's goals. They will be presented with them, and will first have to approve them before they're saved in Bloom",
    parameters: Schema.Object(
      properties: [
        "newGoals" : Schema.Parameter(
          description: "A list of goals for the user to add",
          arrayOf: Schema.Object(
            properties: [
              "metric" : Schema.Parameter(
                enum: SuggestedGoal.Metric.self,
                description: "Which health metric the goal is for"
              ),
              "timePeriod" : Schema.Parameter(
                enum: SuggestedGoal.TimePeriod.self,
                description: "The time period in which the goal must be met"
              ),
              "value": Schema.Parameter(
                type: .number,
                description: "The value of the goal"
              ),
              "unit": Schema.Parameter(
                enum: SuggestedGoal.Unit.self,
                description: "The unit in which the value is measured in"
              )
            ]
          )
        )
      ]
    )
  )

  static let logFood = Assistant.Tool.Function(
    name: .Function.logFood,
    description: "This can be used to log food items for the user",
    parameters: Schema.Object(
      properties: [
        "name": Schema.Parameter(type: .string, description: "The name you would give the food."),
        "foodItems": Schema.Parameter(
          description: "A list of individual food items detected.",
          arrayOf: Schema.Object(
            properties: [
              "name": Schema.Parameter(type: .string, description: "The name of this food item"),
              "servingName": Schema.Parameter(type: .string, description: "A name for a single serving of the food item. It should not contain the name of the item itself, and should contain a number."),
              "servingValue": Schema.Parameter(ref: "quantity"),
              "servingCount": Schema.Parameter(type: .number, description: "The number of servings of the food item you detect."),
              "calories": Schema.Parameter(ref: "quantity"),
              "fat": Schema.Parameter(ref: "quantity"),
              "carbohydrates": Schema.Parameter(ref: "quantity"),
              "protein": Schema.Parameter(ref: "quantity"),
              "saturatedFat": Schema.Parameter(ref: "quantity"),
              "transFat": Schema.Parameter(ref: "quantity"),
              "polyunsaturatedFat": Schema.Parameter(ref: "quantity"),
              "monounsaturatedFat": Schema.Parameter(ref: "quantity"),
              "fiber": Schema.Parameter(ref: "quantity"),
              "sugar": Schema.Parameter(ref: "quantity"),
              "cholesterol": Schema.Parameter(ref: "quantity"),
              "sodium": Schema.Parameter(ref: "quantity"),
              "calcium": Schema.Parameter(ref: "quantity"),
              "iron": Schema.Parameter(ref: "quantity"),
              "potassium": Schema.Parameter(ref: "quantity"),
              "magnesium": Schema.Parameter(ref: "quantity"),
              "zinc": Schema.Parameter(ref: "quantity"),
              "vitaminA": Schema.Parameter(ref: "quantity"),
              "vitaminB6": Schema.Parameter(ref: "quantity"),
              "vitaminB12": Schema.Parameter(ref: "quantity"),
              "vitaminC": Schema.Parameter(ref: "quantity"),
              "vitaminD": Schema.Parameter(ref: "quantity"),
              "vitaminE": Schema.Parameter(ref: "quantity")
            ]
          )
        )
      ],
      references: [
        "quantity" : .quantity
      ]
    )
  )

  static let logWater = Assistant.Tool.Function(
    name: .Function.logWater,
    description: "This can be used to log water for the user",
    parameters: Schema.Object(
      properties: [
        "value" : Schema.Parameter(
          type: .number,
          description: "The amount of water to log"
        ),
        "unit" : Schema.Parameter(
          enum: SocketMessage.LogWaterConsumption.Unit.self,
          description: "The unit the value is measured in"
        )
      ]
    )
  )

  static let logBowelMovement = Assistant.Tool.Function(
    name: .Function.logBowelMovement,
    description: "This can be used to log a bowel movement for the user",
    parameters: Schema.Object(
      properties: [
        "bristolStoolType": Schema.Parameter(
          type: .integer,
          description: "The bristol stool type of the bowel movement"
        ),
        "duration": Schema.Parameter(
          enum: SocketMessage.LogBowelMovement.Duration.self,
          description: "The duration of the bowel movement"
        )
      ]
    )
  )

  static let logWeight = Assistant.Tool.Function(
    name: .Function.logWeight,
    description: "This can be used to log the user's weight",
    parameters: Schema.Object(
      properties: [
        "value": Schema.Parameter(
          type: .number,
          description: "The user's weight"
        ),
        "unit": Schema.Parameter(
          type: .string,
          description: "The unit to measure the weight with"
        )
      ]
    )
  )

  static let logBloodPressure = Assistant.Tool.Function(
    name: .Function.logBloodPressure,
    description: "This can be used to log the user's blood pressure",
    parameters: Schema.Object(
      properties: [
        "systolic": Schema.Parameter(
          type: .integer,
          description: "The systolic measurement of blood pressure"
        ),
        "diastolic": Schema.Parameter(
          type: .integer,
          description: "The diastolic measurement of blood pressure"
        )
      ]
    )
  )
}
