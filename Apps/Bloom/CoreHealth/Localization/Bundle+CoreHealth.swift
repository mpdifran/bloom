//
//  Bundle+CoreHealth.swift
//  CoreHealth
//
//  Created by Mark DiFranco on 2026-08-11.
//

import Foundation

private final class CoreHealthBundleAnchor {}

public extension Bundle {

  /// The CoreHealth framework bundle.
  ///
  /// Strings declared in CoreHealth live in CoreHealth's own String Catalog, so every lookup has to
  /// be bundle-qualified — the default (`Bundle.main`) is the host app or extension, which doesn't
  /// contain these keys.
  static let coreHealth = Bundle(for: CoreHealthBundleAnchor.self)
}
