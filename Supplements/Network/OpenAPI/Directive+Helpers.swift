//
//  Directive+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-06-23.
//

import Foundation
import OpenAPIClient

extension UserDirective {

    var hasDetails: Bool {
        supplementDetails != nil || activityDetails != nil
    }
}
