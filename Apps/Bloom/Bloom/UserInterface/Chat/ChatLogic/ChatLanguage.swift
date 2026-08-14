//
//  ChatLanguage.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-08-13.
//

import Foundation

enum ChatLanguage {

  /// BCP-47 tag describing the language Bud should write in, e.g. "es-MX".
  ///
  /// This is the language the UI actually resolved to, not `Locale.current` — a device set to
  /// Spanish (US) while the app only ships English would otherwise ask Bud to answer in Spanish
  /// with every label around it in English. The region is appended when available so the server can
  /// tell regional variants apart (pt-BR vs pt-PT).
  static var tag: String {
    let language = Bundle.main.preferredLocalizations.first
      ?? Locale.current.language.languageCode?.identifier
      ?? "en"

    guard let region = Locale.current.region?.identifier else {
      return language
    }

    // preferredLocalizations sometimes already carries a region ("zh-Hans-CN").
    guard !language.contains("-") else {
      return language
    }

    return "\(language)-\(region)"
  }
}
