//
//  ShieldActionExtension.swift
//  ShieldActionExtension
//
//  Created by Mark DiFranco on 2024-06-01.
//

import ManagedSettings
import DeviceActivity
import ScreenControl

class ShieldActionExtension: ShieldActionDelegate {
    let store = ManagedSettingsStore()
    let screenController = ScreenUseController.shared

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            addTenMinuteDelayEvent(applicationToken: application)
            store.shield.applications?.remove(application)
            completionHandler(.defer)
        @unknown default:
            fatalError()
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            addTenMinuteDelayEvent(webDomainToken: webDomain)
            store.shield.webDomains?.remove(webDomain)
            completionHandler(.defer)
        @unknown default:
            fatalError()
        }
    }
    
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            addTenMinuteDelayEvent(categoryToken: category)
            removeFromShield(categoryToken: category)
            completionHandler(.defer)
        @unknown default:
            fatalError()
        }
    }
}

private extension ShieldActionExtension {

    func addTenMinuteDelayEvent(
        applicationToken: ApplicationToken? = nil,
        categoryToken: ActivityCategoryToken? = nil,
        webDomainToken: WebDomainToken? = nil
    ) {
        let event = DeviceActivityEvent(
            applications: applicationToken.map { [$0] } ?? [],
            categories: categoryToken.map { [$0] } ?? [],
            webDomains: webDomainToken.map { [$0] } ?? [],
            threshold: .init(minute: 10)
        )

        do {
            try screenController.startMonitoring(events: [.tenMinExtend : event])
        } catch { }
    }

    func removeFromShield(categoryToken: ActivityCategoryToken) {
        switch store.shield.applicationCategories {
        case .all:
            break // TODO: This seems problematic
        case .specific(var categoryTokens, let exceptions):
            categoryTokens.remove(categoryToken)
            store.shield.applicationCategories = .specific(categoryTokens, except: exceptions)
        default:
            break
        }

        switch store.shield.webDomainCategories {
        case .all(let except):
            break // TODO: This seems problematic
        case .specific(var categoryTokens, let exceptions):
            categoryTokens.remove(categoryToken)
            store.shield.webDomainCategories = .specific(categoryTokens, except: exceptions)
        default:
            break
        }
    }
}
