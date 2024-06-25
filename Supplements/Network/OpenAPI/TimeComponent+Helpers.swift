//
//  TimeComponent+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-23.
//

import Foundation
import OpenAPIClient

extension TimeComponent {

    var formattedTimeUsingNow: String? {
        let dateComponents = DateComponents(hour: hour, minute: minute)
        guard let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) else { return nil }
        return DateFormatter.relativeDateTimeMedium.string(from: date)
    }
}
