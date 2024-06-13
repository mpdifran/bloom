//
//  BedtimeActivityView.swift
//  DeviceActivityReportExtension
//
//  Created by Mark DiFranco on 2024-06-12.
//

import SwiftUI

extension BedtimeActivityView {
    struct Configuration {
        let data: [DateInterval : [UsageInfo]]
    }

    struct UsageInfo: Identifiable {
        let id: String
        let name: String
        let duration: TimeInterval
    }
}

struct BedtimeActivityView: View {
    let configuration: Configuration

    var body: some View {
        Text("\(configuration.data.count)")
    }
}

// In order to support previews for your extension's custom views, make sure its source files are
// members of your app's Xcode target as well as members of your extension's target. You can use
// Xcode's File Inspector to modify a file's Target Membership.
#Preview {
    BedtimeActivityView(
        configuration: .init(
            data: [:]
        )
    )
}
