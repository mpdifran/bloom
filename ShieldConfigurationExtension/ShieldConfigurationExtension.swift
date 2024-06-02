//
//  ShieldConfigurationExtension.swift
//  ShieldConfigurationExtension
//
//  Created by Mark DiFranco on 2024-06-01.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit
import SwiftUI

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        shieldConfiguration(for: application.localizedDisplayName ?? "this app")
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        shieldConfiguration(for: webDomain.domain ?? "this website", verb: "visiting")
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: webDomain)
    }
}

private extension ShieldConfigurationExtension {

    func shieldConfiguration(for itemName: String, verb: String = "using") -> ShieldConfiguration {
        let deepSleep = UIColor(named: "DeepSleep")!
        let remSleep = UIColor(named: "REMSleep")!

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterialDark,
            backgroundColor: deepSleep,
            icon: UIImage(systemName: "moon.zzz.fill")?.withTintColor(.yellow),
            title: .init(
                text: "Bloom - Bedtime",
                color: .label
            ),
            subtitle: .init(
                text: "You should avoid \(verb) \(itemName) around bedtime to have a better quality sleep.",
                color: .label
            ),
            primaryButtonLabel: .init(
                text: "Close",
                color: deepSleep
            ),
            primaryButtonBackgroundColor: remSleep,
            secondaryButtonLabel: .init(
                text: "Open Anyway",
                color: remSleep
            )
        )
    }
}
