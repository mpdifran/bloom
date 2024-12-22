//
//  AdminSearchFoodItemGetRequest.swift
//  Bloom-Backend
//
//  Created by Zach Radford on 2024-12-22.
//

import Vapor

struct AdminSearchFoodItemGetRequest: Content {
  let query: String
}
