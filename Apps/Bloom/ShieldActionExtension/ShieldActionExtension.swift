//
//  ShieldActionExtension.swift
//  ShieldActionExtension
//
//  Created by Mark DiFranco on 2024-06-01.
//

import ManagedSettings
import DeviceActivity
import ScreenControl
import UserNotifications

class ShieldActionExtension: ShieldActionDelegate {
    let store = ManagedSettingsStore()
    let screenController = ScreenUseController.shared

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            store.shield.applications?.remove(application)
            addTimeDelay(applicationToken: application)
            completionHandler(.none)
        @unknown default:
            fatalError()
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            store.shield.webDomains?.remove(webDomain)
            addTimeDelay(webDomainToken: webDomain)
            completionHandler(.none)
        @unknown default:
            fatalError()
        }
    }
    
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            store.shield.remove(categoryTokens: [category])
            addTimeDelay(categoryToken: category)
            completionHandler(.none)
        @unknown default:
            fatalError()
        }
    }
}

private extension ShieldActionExtension {

    func addTimeDelay(
        applicationToken: ApplicationToken? = nil,
        categoryToken: ActivityCategoryToken? = nil,
        webDomainToken: WebDomainToken? = nil
    ) {
        do {
            try screenController.startTimeExtensionMonitoring(
                applicationToken: applicationToken,
                webDomainToken: webDomainToken,
                categoryToken: categoryToken
            )
        } catch { }
    }
}
