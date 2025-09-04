//
//  DeviceActivityName+Sleep.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-01.
//

import Foundation
@preconcurrency import DeviceActivity

public extension DeviceActivityName {
    static let sleep = Self("sleep")
    static let timeExtension = Self("timeExtension")
}

public extension DeviceActivityEvent.Name {
    static let timeExtension = Self("timeExtension")
}
