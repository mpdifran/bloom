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
        let deepSleep = UIColor(named: "DeepSleep")!
        let coreSleep = UIColor(named: "CoreSleep")!

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: deepSleep,
            icon: UIImage(systemName: "moon.zzz.fill")?.withTintColor(.yellow),
            title: .init(
                text: "Bloom - Bedtime",
                color: .label
            ),
            subtitle: .init(
                text: "You should avoid using \(application.localizedDisplayName ?? "this app") around bedtime to have a better quality sleep.",
                color: .label
            ),
            primaryButtonLabel: .init(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: coreSleep,
            secondaryButtonLabel: .init(
                text: "Open Anyway",
                color: coreSleep
            )
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        let deepSleep = UIColor(named: "DeepSleep")!
        let coreSleep = UIColor(named: "CoreSleep")!
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: deepSleep,
            icon: UIImage(systemName: "moon.zzz.fill")?.withTintColor(.yellow),
            title: .init(
                text: "Bloom - Bedtime",
                color: .label
            ),
            subtitle: .init(
                text: "You should avoid visiting \(webDomain.domain ?? "this website") around bedtime to have a better quality sleep.",
                color: .label
            ),
            primaryButtonLabel: .init(
                text: "Close",
                color: .white
            ),
            primaryButtonBackgroundColor: coreSleep,
            secondaryButtonLabel: .init(
                text: "Open Anyway",
                color: coreSleep
            )
        )
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: webDomain)
    }
}
