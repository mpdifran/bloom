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
        shieldConfiguration(
            message: "You should avoid using \(application.localizedDisplayName ?? "this app") around bedtime to have a better quality sleep."
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        shieldConfiguration(
            message: "You should avoid using \(category.localizedDisplayName ?? "") apps like \(application.localizedDisplayName ?? "this app") around bedtime to have a better quality sleep."
        )
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        shieldConfiguration(
            message: "You should avoid visiting \(webDomain.domain ?? "this website") around bedtime to have a better quality sleep."
        )
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        shieldConfiguration(
            message: "You should avoid visiting \(category.localizedDisplayName ?? "") websites like \(webDomain.domain ?? "this website") around bedtime to have a better quality sleep."
        )
    }
}

private extension ShieldConfigurationExtension {

    func shieldConfiguration(message: String) -> ShieldConfiguration {
        let deepSleep = UIColor(named: "DeepSleep")!
        let bloomTint = UIColor(named: "BloomTint")!
        let remSleep = UIColor(named: "REMSleep")!

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterialDark,
            backgroundColor: deepSleep,
            icon: UIImage(systemName: "moon.zzz.fill")?.withTintColor(bloomTint),
            title: .init(
                text: "Bloom - Bedtime",
                color: .white
            ),
            subtitle: .init(
                text: message,
                color: .white
            ),
            primaryButtonLabel: .init(
                text: "Close App",
                color: .white
            ),
            primaryButtonBackgroundColor: bloomTint,
            secondaryButtonLabel: .init(
                text: "10 More Minutes",
                color: bloomTint
            )
        )
    }
}
