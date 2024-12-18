//
//  CLLocation+Identifiable.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-18.
//

import Foundation
import CoreLocation

extension CLLocation: @retroactive Identifiable {
  public var id: Int { hashValue }
}
