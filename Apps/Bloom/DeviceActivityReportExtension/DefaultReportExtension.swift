//
//  DefaultReportExtension.swift
//  DeviceActivityReportExtension
//
//  Created by Mark DiFranco on 2024-06-12.
//

import DeviceActivity
import SwiftUI

@main
struct DefaultReportExtension: DeviceActivityReportExtension {

    var body: some DeviceActivityReportScene {
        BedtimeActivityReport { configuration in
            BedtimeActivityView(configuration: configuration)
        }
    }
}
