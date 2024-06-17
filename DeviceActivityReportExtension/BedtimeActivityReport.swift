//
//  BedtimeActivityReport.swift
//  DeviceActivityReportExtension
//
//  Created by Mark DiFranco on 2024-06-12.
//

import DeviceActivity
import SwiftUI
import ScreenControl

struct BedtimeActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .bedtimeActivity
    let content: (BedtimeActivityView.Configuration) -> BedtimeActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> BedtimeActivityView.Configuration {
        var result = [DateInterval : [BedtimeActivityView.UsageInfo]]()

        for await activityData in data {
            for await activitySegment in activityData.activitySegments {
                let dateInterval = activitySegment.dateInterval
                var usageInfos = result[dateInterval, default: []]

                for await categoryActivity in activitySegment.categories {
                    for await applicationActivity in categoryActivity.applications {
                        guard applicationActivity.totalActivityDuration > 0.1 else { continue }

                        let usageInfo = BedtimeActivityView.UsageInfo(
                            id: applicationActivity.application.bundleIdentifier ?? UUID().uuidString,
                            name: applicationActivity.application.localizedDisplayName ?? "Unknown App",
                            duration: applicationActivity.totalActivityDuration
                        )
                        usageInfos.append(usageInfo)
                    }

                    for await webDomainActivity in categoryActivity.webDomains {
                        guard webDomainActivity.totalActivityDuration > 0.1 else { continue }

                        let usageInfo = BedtimeActivityView.UsageInfo(
                            id: webDomainActivity.webDomain.domain ?? UUID().uuidString,
                            name: webDomainActivity.webDomain.domain ?? "Unknown Website",
                            duration: webDomainActivity.totalActivityDuration
                        )
                        usageInfos.append(usageInfo)
                    }
                }

                result[dateInterval] = usageInfos
            }
        }

        return BedtimeActivityView.Configuration(data: result)
    }
}
