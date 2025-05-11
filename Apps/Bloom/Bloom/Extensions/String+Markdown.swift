//
//  String+Markdown.swift
//  Bloom
//
//  Created by Zach Radford on 2025-05-11.
//

import SwiftUI

public extension String {
  var formattedMarkdown: LocalizedStringKey {
    LocalizedStringKey(self)
  }
}
