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
                "startDate" : Schema.Parameter(type: .string, description: "The start date of the query in ISO-8601 format (e.g., 2025-01-03T12:00:00Z). This time must be in the user's timezone."),
                "endDate" : Schema.Parameter(type: .string, description: "The end date of the query in ISO-8601 format (e.g., 2025-04-03T12:00:00Z). This time must be in the user's timezone."),
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
}
