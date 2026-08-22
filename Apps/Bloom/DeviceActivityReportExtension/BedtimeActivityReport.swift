//
//  BedtimeActivityReport.swift
//  DeviceActivityReportExtension
//
//  Created by Mark DiFranco on 2024-06-12.
//

@preconcurrency import DeviceActivity
import SwiftUI
import ScreenControl

struct BedtimeActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .bedtimeActivity
    let content: (BedtimeActivityView.Configuration) -> BedtimeActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> BedtimeActivityView.Configuration {
        var result = [BedtimeActivityView.UsageInfo]()

        for await activityData in data {
            for await activitySegment in activityData.activitySegments {

                for await categoryActivity in activitySegment.categories {
                    for await applicationActivity in categoryActivity.applications {
                        guard applicationActivity.totalActivityDuration > 1 else { continue }

                        let id = applicationActivity.application.bundleIdentifier ?? UUID().uuidString
                        let name = applicationActivity.application.localizedDisplayName
                            ?? String(localized: "Unknown App", comment: "Fallback name for an app with no display name")
                        let duration = applicationActivity.totalActivityDuration

                        if let index = result.firstIndex(where: { $0.id == id }) {
                            result[index].duration += duration
                        } else {
                            let usageInfo = BedtimeActivityView.UsageInfo(
                                id: id,
                                name: name,
                                duration: duration
                            )
                            result.append(usageInfo)
                        }
                    }

                    for await webDomainActivity in categoryActivity.webDomains {
                        guard webDomainActivity.totalActivityDuration > 1 else { continue }

                        let id = webDomainActivity.webDomain.domain ?? UUID().uuidString
                        let name = webDomainActivity.webDomain.domain
                            ?? String(localized: "Unknown Website", comment: "Fallback name for a website with no domain")
                        let duration = webDomainActivity.totalActivityDuration

                        if let index = result.firstIndex(where: { $0.id == id }) {
                            result[index].duration += duration
                        } else {
                            let usageInfo = BedtimeActivityView.UsageInfo(
                                id: id,
                                name: name,
                                duration: duration
                            )
                            result.append(usageInfo)
                        }
                    }
                }
            }
        }

        return BedtimeActivityView.Configuration(usage: result)
    }
}
