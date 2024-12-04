//
//  UnverifiedFoodGetRequest.swift
//  Bloom-Backend
//
//  Created by Zach Radford on 2024-11-30.
//

import Vapor

struct UnverifiedFoodGetRequest: Content {
  let limit: Int?
}
