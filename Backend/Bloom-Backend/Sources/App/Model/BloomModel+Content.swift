//
//  BloomModel+Content.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import BloomModel
import Vapor

extension FoodAutocompleteRequest: @retroactive Content { }
extension FoodAutocompleteResponse: @retroactive Content { }
