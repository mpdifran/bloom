//
//  ChatLanguageInstruction.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2026-08-13.
//

import Foundation

/// Turns the client's BCP-47 locale tag into a line appended to the assistant's instructions.
///
/// The tag is client-supplied and the result carries system authority, so nothing from the client
/// is ever interpolated directly: the tag is parsed into a language (and optional region) code, and
/// only names looked up from Foundation's own tables make it into the prompt. Anything unrecognized
/// yields nil, which leaves the assistant's language behaviour exactly as it was.
enum ChatLanguageInstruction {

  static func instruction(forLocaleTag tag: String?, interfaceTag: String? = nil) -> String? {
    guard let displayName = languageDisplayName(forLocaleTag: tag) else { return nil }

    return """

      Language: Write your prose in \(displayName) by default. If the user writes you a full sentence in a different language, switch to that language and stay in it for the rest of the conversation. Ignore short or ambiguous messages when deciding - a food name, a number, an acknowledgement or an emoji is not a request to change language, so keep writing in the language you were already using.\(interfaceClause(proseName: displayName, interfaceTag: interfaceTag)) The health data you are given is always in English - translate it when you refer to it, and never mention that it arrived in English. Inside ```json blocks, keep every key and every enumerated value exactly as specified in English; only free-text values such as names and notes may be written in the user's language.
      """
  }

  /// The interface is limited to the localizations we ship; the assistant is not. When the two
  /// languages differ the model has to be told, or it will translate on-screen labels that the user
  /// is actually seeing in another language.
  static func interfaceClause(proseName: String, interfaceTag: String?) -> String {
    guard let interfaceTag, !interfaceTag.isEmpty else { return "" }

    // languageDisplayName returns nil for English, which is exactly the common case here.
    let interfaceName = languageDisplayName(forLocaleTag: interfaceTag) ?? "English"
    guard interfaceName != proseName else { return "" }

    return " The app's interface is displayed in \(interfaceName), so when you refer to a button, tab or screen by name, give that name in \(interfaceName) even though the rest of your reply is in \(proseName)."
  }

  /// English display name for the tag, e.g. "Spanish" or "Portuguese (Brazil)".
  /// Returns nil for English (the prompt's own language, so no instruction is needed), for absent
  /// tags, and for anything that doesn't parse as a language Foundation knows.
  static func languageDisplayName(forLocaleTag tag: String?) -> String? {
    guard let tag, !tag.isEmpty, tag.count <= 35 else { return nil }

    let components = tag.split(separator: "-", omittingEmptySubsequences: true)
    guard let first = components.first else { return nil }

    let languageCode = String(first).lowercased()
    guard (2...3).contains(languageCode.count), languageCode.allSatisfy({ $0.isLetter }) else {
      return nil
    }

    // English is what the base prompt is already written in.
    guard languageCode != "en" else { return nil }

    // Names come from Foundation's tables rather than from the client's string.
    let english = Locale(identifier: "en_US")
    guard
      let languageName = english.localizedString(forLanguageCode: languageCode),
      languageName.lowercased() != languageCode
    else {
      return nil
    }

    guard let regionName = regionName(from: components, locale: english) else {
      return sanitized(languageName)
    }
    return sanitized("\(languageName) (\(regionName))")
  }
}

private extension ChatLanguageInstruction {

  static func regionName(from components: [Substring], locale: Locale) -> String? {
    // "es-MX" and "zh-Hans-CN" both carry the region last; "es" carries none.
    guard components.count > 1, let last = components.last else { return nil }

    let regionCode = String(last).uppercased()
    guard regionCode.count == 2, regionCode.allSatisfy({ $0.isLetter }) else { return nil }

    // Foundation answers unknown codes with a placeholder ("Unknown Region") rather than nil, so
    // check the code against the ISO list first.
    guard Locale.Region(regionCode).isISORegion else { return nil }

    guard
      let name = locale.localizedString(forRegionCode: regionCode),
      name.uppercased() != regionCode,
      !name.localizedCaseInsensitiveContains("unknown")
    else {
      return nil
    }
    return name
  }

  /// Belt and braces: the names come from Foundation, so this should never reject anything, but the
  /// value is about to be given system authority in a prompt.
  static func sanitized(_ value: String) -> String? {
    let allowed: (Character) -> Bool = { character in
      character.isLetter || character.isWhitespace || "()-',.".contains(character)
    }
    return value.allSatisfy(allowed) ? value : nil
  }
}
