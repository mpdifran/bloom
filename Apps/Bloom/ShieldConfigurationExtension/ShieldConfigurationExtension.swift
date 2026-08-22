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
        let appName = application.localizedDisplayName ?? Self.thisApp
        return shieldConfiguration(
            message: String(
                localized: "You should avoid using \(appName) around bedtime to have a better quality sleep.",
                comment: "Bedtime shield message, %@ is the app's name"
            )
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        let categoryName = category.localizedDisplayName ?? ""
        let appName = application.localizedDisplayName ?? Self.thisApp
        return shieldConfiguration(
            message: String(
                localized: "You should avoid using \(categoryName) apps like \(appName) around bedtime to have a better quality sleep.",
                comment: "Bedtime shield message, first %@ is the category name, second %@ is the app's name"
            )
        )
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        let domain = webDomain.domain ?? Self.thisWebsite
        return shieldConfiguration(
            message: String(
                localized: "You should avoid visiting \(domain) around bedtime to have a better quality sleep.",
                comment: "Bedtime shield message, %@ is the website's domain"
            )
        )
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        let categoryName = category.localizedDisplayName ?? ""
        let domain = webDomain.domain ?? Self.thisWebsite
        return shieldConfiguration(
            message: String(
                localized: "You should avoid visiting \(categoryName) websites like \(domain) around bedtime to have a better quality sleep.",
                comment: "Bedtime shield message, first %@ is the category name, second %@ is the website's domain"
            )
        )
    }

    private static var thisApp: String {
        String(localized: "this app", comment: "Bedtime shield fallback for an app with no name")
    }

    private static var thisWebsite: String {
        String(localized: "this website", comment: "Bedtime shield fallback for a website with no domain")
    }
}

private extension ShieldConfigurationExtension {

    func shieldConfiguration(message: String) -> ShieldConfiguration {
        let deepSleep = UIColor(named: "DeepSleep")!
        let bloomTint = UIColor(named: "BloomTint")!
//        let remSleep = UIColor(named: "REMSleep")!

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterialDark,
            backgroundColor: deepSleep,
            icon: UIImage(systemName: "moon.zzz.fill")?.withTintColor(bloomTint),
            title: ShieldConfiguration.Label(
                text: String(localized: "Bloom - Bedtime", comment: "Bedtime shield title"),
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: message,
                color: .white
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: String(localized: "Close App", comment: "Bedtime shield primary button"),
                color: .white
            ),
            primaryButtonBackgroundColor: bloomTint,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: String(localized: "10 More Minutes", comment: "Bedtime shield secondary button"),
                color: bloomTint
            )
        )
    }
}
