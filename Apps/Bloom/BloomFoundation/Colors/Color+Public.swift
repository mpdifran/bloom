//
//  Color+Public.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-01.
//

import SwiftUI

public extension ShapeStyle where Self == Color {
  static var mutedBlue: Self           { Color("mutedBlue", bundle: BundleToken.bundle) }
  static var mutedGreen: Self          { Color("mutedGreen", bundle: BundleToken.bundle) }
  static var mutedIndigo: Self         { Color("mutedIndigo", bundle: BundleToken.bundle) }
  static var mutedLightBlue: Self      { Color("mutedLightBlue", bundle: BundleToken.bundle) }
  static var mutedOrange: Self         { Color("mutedOrange", bundle: BundleToken.bundle) }
  static var mutedPink: Self           { Color("mutedPink", bundle: BundleToken.bundle) }
  static var mutedPurple: Self         { Color("mutedPurple", bundle: BundleToken.bundle) }
  static var mutedRed: Self            { Color("mutedRed", bundle: BundleToken.bundle) }
  static var mutedTeal: Self           { Color("mutedTeal", bundle: BundleToken.bundle) }
  static var mutedYellow: Self         { Color("mutedYellow", bundle: BundleToken.bundle) }
  static var lilacBackground: Self     { Color("LilacBackground", bundle: BundleToken.bundle) }
  static var lilacTint: Self           { Color("LilacTint", bundle: BundleToken.bundle) }
  static var marineBackground: Self    { Color("MarineBackground", bundle: BundleToken.bundle) }
  static var marineTint: Self          { Color("MarineTint", bundle: BundleToken.bundle) }
  static var sunflowerBackground: Self { Color("SunflowerBackground", bundle: BundleToken.bundle) }
  static var sunflowerTint: Self       { Color("SunflowerTint", bundle: BundleToken.bundle) }
  static var monitorLow: Self          { Color("monitorLow", bundle: BundleToken.bundle) }
  static var monitorTypical: Self      { Color("monitorTypical", bundle: BundleToken.bundle) }
  static var monitorHigh: Self         { Color("monitorHigh", bundle: BundleToken.bundle) }
  static var softPink: Self            { Color("softPink", bundle: BundleToken.bundle) }
  static var softRed: Self             { Color("softRed", bundle: BundleToken.bundle) }
}

public extension Color {
  static let mutedBlue           = Color("mutedBlue", bundle: BundleToken.bundle)
  static let mutedGreen          = Color("mutedGreen", bundle: BundleToken.bundle)
  static let mutedIndigo         = Color("mutedIndigo", bundle: BundleToken.bundle)
  static let mutedLightBlue      = Color("mutedLightBlue", bundle: BundleToken.bundle)
  static let mutedOrange         = Color("mutedOrange", bundle: BundleToken.bundle)
  static let mutedPink           = Color("mutedPink", bundle: BundleToken.bundle)
  static let mutedPurple         = Color("mutedPurple", bundle: BundleToken.bundle)
  static let mutedRed            = Color("mutedRed", bundle: BundleToken.bundle)
  static let mutedTeal           = Color("mutedTeal", bundle: BundleToken.bundle)
  static let mutedYellow         = Color("mutedYellow", bundle: BundleToken.bundle)
  static let lilacBackground     = Color("LilacBackground", bundle: BundleToken.bundle)
  static let lilacTint           = Color("LilacTint", bundle: BundleToken.bundle)
  static let marineBackground    = Color("MarineBackground", bundle: BundleToken.bundle)
  static let marineTint          = Color("MarineTint", bundle: BundleToken.bundle)
  static let sunflowerBackground = Color("SunflowerBackground", bundle: BundleToken.bundle)
  static let sunflowerTint       = Color("SunflowerTint", bundle: BundleToken.bundle)
  static let monitorLow          = Color("monitorLow", bundle: BundleToken.bundle)
  static let monitorTypical      = Color("monitorTypical", bundle: BundleToken.bundle)
  static let monitorHigh         = Color("monitorHigh", bundle: BundleToken.bundle)
  static let softPink            = Color("softPink", bundle: BundleToken.bundle)
  static let softRed             = Color("softRed", bundle: BundleToken.bundle)
}

private class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
      return Bundle.module
    #else
      return Bundle(for: BundleToken.self)
    #endif
  }()
}
