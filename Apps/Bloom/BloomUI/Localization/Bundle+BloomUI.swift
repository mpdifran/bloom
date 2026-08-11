//
//  Bundle+BloomUI.swift
//  BloomUI
//
//  Created by Mark DiFranco on 2026-08-11.
//

import Foundation

private final class BloomUIBundleAnchor {}

public extension Bundle {

  /// The BloomUI framework bundle.
  ///
  /// Strings declared in BloomUI live in BloomUI's own String Catalog, so every lookup has to be
  /// bundle-qualified — the default (`Bundle.main`) is the host app or extension, which doesn't
  /// contain these keys.
  static let bloomUI = Bundle(for: BloomUIBundleAnchor.self)
}
