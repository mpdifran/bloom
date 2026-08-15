//
//  ChatLanguage.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-08-13.
//

import Foundation

/// The two languages the AI surfaces need to know about.
///
/// They are not the same thing. The interface can only be shown in a language we ship a
/// localization for, but the assistant can write in any language the model speaks - so a Dutch user
/// on an English build should read Bud in Dutch even though the tab bar says "Today".
enum ChatLanguage {

  /// BCP-47 tag for the language generated prose should be written in, e.g. "nl-NL".
  ///
  /// This follows the user's device preference, deliberately not `Bundle.main.preferredLocalizations`:
  /// tying it to our shipped localizations would cap the assistant at the languages we happen to
  /// have translated, which is a limit the model doesn't actually have.
  static var proseTag: String {
    tag(for: Locale.preferredLanguages.first)
  }

  /// BCP-47 tag for the language the interface is displayed in, e.g. "en-CA".
  ///
  /// This is what the app's bundle actually resolved to, so it reflects the labels the user sees.
  /// The server passes it to the model so on-screen names aren't translated out from under them.
  static var interfaceTag: String {
    tag(for: Bundle.main.preferredLocalizations.first)
  }
}

private extension ChatLanguage {

  /// Normalizes an identifier to a language tag, appending the current region when the identifier
  /// doesn't already carry one, so the server can tell pt-BR from pt-PT.
  static func tag(for identifier: String?) -> String {
    let language = identifier
      ?? Locale.current.language.languageCode?.identifier
      ?? "en"

    guard !language.contains("-"), let region = Locale.current.region?.identifier else {
      return language
    }

    return "\(language)-\(region)"
  }
}
