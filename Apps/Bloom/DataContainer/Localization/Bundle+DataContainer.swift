//
//  Bundle+DataContainer.swift
//  DataContainer
//
//  Created by Mark DiFranco on 2026-08-11.
//

import Foundation

private final class DataContainerBundleAnchor {}

public extension Bundle {

  /// The DataContainer framework bundle.
  ///
  /// Strings declared in DataContainer live in DataContainer's own String Catalog, so every lookup
  /// has to be bundle-qualified — the default (`Bundle.main`) is the host app or extension, which
  /// doesn't contain these keys.
  static let dataContainer = Bundle(for: DataContainerBundleAnchor.self)
}
