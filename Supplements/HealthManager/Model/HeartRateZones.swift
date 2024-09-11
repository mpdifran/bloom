//
//  HeartRateZones.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-20.
//

import Foundation
import HealthKit

struct HeartRateZones: Hashable {
    let heartRateReserve: Double
    let restingHeartRate: Double
    let maxHeartRate: Double
    let zone1: Double
    let zone2: Double
    let zone3: Double
    let zone4: Double
    let zone5: Double
}

extension HeartRateZones {

    var zone1RangeString: String {
        "\(zone1.format()) - \(zone2.format()) bpm"
    }

    var zone2RangeString: String {
        "\(zone2.format()) - \(zone3.format()) bpm"
    }

    var zone3RangeString: String {
        "\(zone3.format()) - \(zone4.format()) bpm"
    }

    var zone4RangeString: String {
        "\(zone4.format()) - \(zone5.format()) bpm"
    }

    var zone5RangeString: String {
        "\(zone5.format()) - \(maxHeartRate.format()) bpm"
    }
}
