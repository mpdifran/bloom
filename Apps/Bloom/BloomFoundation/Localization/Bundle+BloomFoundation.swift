//
//  Bundle+BloomFoundation.swift
//  BloomFoundation
//

import Foundation

private final class BloomFoundationBundleAnchor {}

public extension Bundle {

  /// The BloomFoundation framework bundle.
  ///
  /// Strings declared in BloomFoundation live in BloomFoundation's own String Catalog, so every
  /// lookup has to be bundle-qualified — the default (`Bundle.main`) is the host app or extension,
  /// which doesn't contain these keys.
  static let bloomFoundation = Bundle(for: BloomFoundationBundleAnchor.self)
}
