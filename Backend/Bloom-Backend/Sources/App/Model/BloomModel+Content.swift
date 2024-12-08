//
//  BloomModel+Content.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import BloomModel
import Vapor

extension AdminUpdateFoodItemRequest: @retroactive Content { }
extension AdminUpdateFoodItemResponse: @retroactive Content { }
extension EstimateFoodCaloriesRequest: @retroactive Content { }
extension EstimateFoodCaloriesResponse: @retroactive Content { }
extension FoodAutocompleteRequest: @retroactive Content { }
extension FoodAutocompleteResponse: @retroactive Content { }
extension FoodSearchRequest: @retroactive Content { }
extension FoodSearchResponse: @retroactive Content { }
extension UploadNewFoodRequest: @retroactive Content { }
extension UploadNewFoodResponse: @retroactive Content { }
extension UnverifiedFoodItemsResponse: @retroactive Content { }
extension AuthenticationRequest: @retroactive Content { }
extension AuthenticationResponse: @retroactive Content { }
