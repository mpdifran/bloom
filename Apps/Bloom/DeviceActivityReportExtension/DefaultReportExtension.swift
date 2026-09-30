//
//  DefaultReportExtension.swift
//  DeviceActivityReportExtension
//
//  Created by Mark DiFranco on 2024-06-12.
//

import DeviceActivity
import SwiftUI
import BloomFoundation

@main
struct DefaultReportExtension: DeviceActivityReportExtension {

    init() {
        CrashReporter.shared.install()
    }

    var body: some DeviceActivityReportScene {
        BedtimeActivityReport { configuration in
            BedtimeActivityView(configuration: configuration)
        }
    }
}
