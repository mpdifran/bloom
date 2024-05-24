//
//  ActivityModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import Foundation

struct ActivityModel: Codable, Hashable, Identifiable {
    var id: String { activityName + reasonForActivity + urlToBookActivity.absoluteString }

    let activityName: String
    let reasonForActivity: String
    let sfSymbolName: String?
    let urlToBookActivity: URL
    let distanceToUserInMeters: Double // meters
}
