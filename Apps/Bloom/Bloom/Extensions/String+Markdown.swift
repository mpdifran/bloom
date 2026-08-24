//
//  String+Markdown.swift
//  Bloom
//
//  Created by Zach Radford on 2025-05-11.
//

import SwiftUI

public extension String {
  /// Converts a `String` into a `LocalizedStringKey` to enable Markdown formatting and localization in SwiftUI `Text` views.
  ///
  /// This allows you to use Markdown syntax (e.g., `**bold**`, `_italic_`) directly within a `String`,
  /// and render it using `Text(message.formattedMarkdown)`.
  ///
  /// - Important: Only for first-party strings. Anything the model or the user wrote should use
  ///   ``attributedMarkdown`` instead - see the note there.
  ///
  /// - Returns: A `LocalizedStringKey` that SwiftUI's `Text` view can render with Markdown and localization support.
  var formattedMarkdown: LocalizedStringKey {
    LocalizedStringKey(self)
  }

  /// Markdown for text Bloom did not write.
  ///
  /// `LocalizedStringKey` is the wrong tool for arbitrary text on two counts. It looks the string up
  /// in the localization table first, so a message that happens to match a key is silently replaced.
  /// And `%` is a format specifier to it - which stopped being hypothetical once assistant replies
  /// began carrying cited URLs, where `%20` and friends are routine.
  ///
  /// `.inlineOnlyPreservingWhitespace` keeps line breaks intact, so lists still read as lists, while
  /// still resolving links, bold and italics.
  var attributedMarkdown: AttributedString {
    (try? AttributedString(
      markdown: self,
      options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )) ?? AttributedString(self)
  }
}
