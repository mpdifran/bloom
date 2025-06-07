//
//  Response.Function+Constants.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-22.
//

import Foundation
import OpenAIKit
import BloomModel

extension Response.Function {
  static let queryUserHealthData = Response.Function(
    name: .Function.queryUserHealthData,
    description: "A function to query health data about the user. You can use this function to help answer the user's questions. You are allowed to include multiple data types to get a better picture of the user's health. Some data may be missing if the user hasn't recorded it.",
    parameters: Schema.Object(
      properties: [
        "queries" : Schema.Parameter(
          description: "A list of user health data queries you would like to perform.",
          arrayOf: .object(
            Schema.Object(
              properties: [
                "startDate" : Schema.Parameter(type: .string, description: "The start date of the query in ISO-8601 format. IMPORTANT: Use the user's timezone from the demographics data, not UTC (e.g., for Eastern timezone use 2025-01-03T12:00:00-05:00, not Z)."),
                "endDate" : Schema.Parameter(type: .string, description: "The end date of the query in ISO-8601 format. IMPORTANT: Use the user's timezone from the demographics data, not UTC (e.g., for Eastern timezone use 2025-04-03T12:00:00-05:00, not Z)."),
                "dataType": Schema.Parameter(
                  enum: SocketMessage.QueryDataType.self,
                  description: "The type of health data to query"
                )
              ]
            )
          )
        )
      ]
    )
  )

  static let createUserFact = Response.Function(
    name: .Function.createUserFact,
    description: "Store one or more learned facts about the user for future reference. This function should be used as a last resort if no other function or tool can be used. This information is stored in your memory only.",
    parameters: Schema.Object(
      properties: [
        "facts": Schema.Parameter(
          description: "Array of facts to store",
          arrayOf: .object(
            Schema.Object(
              properties: [
                "fact": Schema.Parameter(type: .string, description: "The fact to store about the user"),
                "revisitDate": Schema.Parameter(type: .string, description: "ISO8601 date when to revisit this fact to see if it's still valid")
              ]
            )
          )
        )
      ]
    )
  )

  static let deleteUserFact = Response.Function(
    name: .Function.deleteUserFact,
    description: "Delete one or more stored user facts",
    parameters: Schema.Object(
      properties: [
        "factIDs": Schema.Parameter(
          description: "Array of fact IDs to delete",
          arrayOf: .parameter(
            .init(
              type: .string,
              description: "A fact ID to delete"
            )
          )
        )
      ]
    )
  )
}
