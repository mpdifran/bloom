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

        let result = await data
            .flatMap { activityData in
                activityData.activitySegments
            }
            .reduce([DateInterval : [BedtimeActivityView.UsageInfo]]()) { (partialResult, activitySegment) in
                var partialResult = partialResult
//                let dateInterval = activitySegment.dateInterval
//                var usageInfos = partialResult[dateInterval, default: []]
//
//                let newUsageInfos = await activitySegment.categories.flatMap { categoryActivity in
//                    let appUsageInfos = categoryActivity.applications.map { applicationActivity in
//                        BedtimeActivityView.UsageInfo(
//                            id: applicationActivity.application.bundleIdentifier ?? UUID().uuidString,
//                            name: applicationActivity.application.localizedDisplayName ?? "Unknown App",
//                            duration: applicationActivity.totalActivityDuration
//                        )
//                    }
//                    let webDomainUsageInfos = categoryActivity.webDomains.map { webDomainActivity in
//                        BedtimeActivityView.UsageInfo(
//                            id: webDomainActivity.webDomain.token ?? UUID().uuidString,
//                            name: webDomainActivity.webDomain.domain ?? "Unknown Website",
//                            duration: webDomainActivity.totalActivityDuration
//                        )
//                    }
//
//                    return appUsageInfos + webDomainUsageInfos
//                }
//
//                usageInfos.append(contentsOf: newUsageInfos)
//                partialResult[dateInterval] = usageInfos

                return partialResult
            }


//        // Reformat the data into a configuration that can be used to create
//        // the report's view.
//        let formatter = DateComponentsFormatter()
//        formatter.allowedUnits = [.day, .hour, .minute, .second]
//        formatter.unitsStyle = .abbreviated
//        formatter.zeroFormattingBehavior = .dropAll
//        
//        let totalActivityDuration = await data.flatMap { $0.activitySegments }.reduce(0, {
//            $0 + $1.totalActivityDuration
//        })
//        let totalActivity = formatter.string(from: totalActivityDuration) ?? "No activity data"

        return BedtimeActivityView.Configuration(data: result)
    }
}
