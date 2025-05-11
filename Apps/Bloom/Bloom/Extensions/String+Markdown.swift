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
  /// - Returns: A `LocalizedStringKey` that SwiftUI's `Text` view can render with Markdown and localization support.
  var formattedMarkdown: LocalizedStringKey {
    LocalizedStringKey(self)
  }
}
