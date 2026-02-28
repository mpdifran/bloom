//
//  CelebrationPreferences.swift
//  Bloom
//
//  Created by Claude on 2026-02-26.
//

import Foundation
import SwiftUI

/// Manages user preferences for celebration milestone modals.
public final class CelebrationPreferences: ObservableObject {

  public static let shared = CelebrationPreferences()

  @AppStorage("celebrations.enabled")
  public var celebrationsEnabled: Bool = true

  private init() {}
}
