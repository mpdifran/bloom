//
//  ManagedSettingStore+Mutating.swift
//  ScreenControl
//
//  Created by Mark DiFranco on 2024-06-03.
//

import Foundation
import ManagedSettings

public extension ShieldSettings {

    /// Removes the `categoryToken` from both the `applicationCategories` and `webDomainCategories`.
    mutating func remove(categoryTokens: Set<ActivityCategoryToken>) {
        switch applicationCategories {
        case .all:
            applicationCategories = ShieldSettings.applicationCategories.defaultValue
        case .specific(let tokens, let exceptions):
            applicationCategories = .specific(tokens.subtracting(categoryTokens), except: exceptions)
        default:
            break
        }

        switch webDomainCategories {
        case .all:
            webDomainCategories = ShieldSettings.webDomainCategories.defaultValue
        case .specific(let tokens, let exceptions):
            webDomainCategories = .specific(tokens.subtracting(categoryTokens), except: exceptions)
        default:
            break
        }
    }

    mutating func clearShield() {
        applications = nil
        webDomains = nil
        applicationCategories = nil
        webDomainCategories = nil
    }
}
