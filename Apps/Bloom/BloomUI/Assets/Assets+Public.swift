//
//  Assets+Public.swift
//  BloomUI
//
//  Created by Claude Code on 2025-10-19.
//

import SwiftUI

public extension ImageResource {
  // Today Scenery
  static let morningScenery   = ImageResource(name: "Morning Scenery", bundle: BundleToken.bundle)
  static let afternoonScenery = ImageResource(name: "Afternoon Scenery", bundle: BundleToken.bundle)
  static let eveningScenery   = ImageResource(name: "Evening Scenery", bundle: BundleToken.bundle)
  static let nightScenery     = ImageResource(name: "Night Scenery", bundle: BundleToken.bundle)

  // Bud Characters
  static let budBicycle          = ImageResource(name: "Bud Bicycle", bundle: BundleToken.bundle)
  static let budCoach            = ImageResource(name: "Bud Coach", bundle: BundleToken.bundle)
  static let budGroggy           = ImageResource(name: "Bud Groggy", bundle: BundleToken.bundle)
  static let budPeek             = ImageResource(name: "Bud Peek", bundle: BundleToken.bundle)
  static let budRunning          = ImageResource(name: "Bud Running", bundle: BundleToken.bundle)
  static let budSalad            = ImageResource(name: "Bud Salad", bundle: BundleToken.bundle)
  static let budSleepy           = ImageResource(name: "Bud Sleepy", bundle: BundleToken.bundle)
  static let budSmoothie         = ImageResource(name: "Bud Smoothie", bundle: BundleToken.bundle)
  static let budStrengthTraining = ImageResource(name: "Bud Strength Training", bundle: BundleToken.bundle)
  static let budStressed         = ImageResource(name: "Bud Stressed", bundle: BundleToken.bundle)
  static let budSuperhero        = ImageResource(name: "Bud Superhero", bundle: BundleToken.bundle)
  static let budThinking         = ImageResource(name: "Bud Thinking", bundle: BundleToken.bundle)
  static let budTrophy           = ImageResource(name: "Bud Trophy", bundle: BundleToken.bundle)
  static let budWorkout          = ImageResource(name: "Bud Workout", bundle: BundleToken.bundle)
  static let budYoga             = ImageResource(name: "Bud Yoga", bundle: BundleToken.bundle)
  static let budHealthApp        = ImageResource(name: "Bud Health App", bundle: BundleToken.bundle)
}

#if os(iOS)
public extension UIImage {
  // Today Scenery
  static var morningScenery: UIImage { UIImage(resource: .morningScenery) }
  static var afternoonScenery: UIImage { UIImage(resource: .afternoonScenery) }
  static var eveningScenery: UIImage { UIImage(resource: .eveningScenery) }
  static var nightScenery: UIImage { UIImage(resource: .nightScenery) }

  // Bud Characters
  static var budBicycle: UIImage { UIImage(resource: .budBicycle) }
  static var budCoach: UIImage { UIImage(resource: .budCoach) }
  static var budGroggy: UIImage { UIImage(resource: .budGroggy) }
  static var budPeek: UIImage { UIImage(resource: .budPeek) }
  static var budRunning: UIImage { UIImage(resource: .budRunning) }
  static var budSalad: UIImage { UIImage(resource: .budSalad) }
  static var budSleepy: UIImage { UIImage(resource: .budSleepy) }
  static var budSmoothie: UIImage { UIImage(resource: .budSmoothie) }
  static var budStrengthTraining: UIImage { UIImage(resource: .budStrengthTraining) }
  static var budStressed: UIImage { UIImage(resource: .budStressed) }
  static var budSuperhero: UIImage { UIImage(resource: .budSuperhero) }
  static var budThinking: UIImage { UIImage(resource: .budThinking) }
  static var budTrophy: UIImage { UIImage(resource: .budTrophy) }
  static var budWorkout: UIImage { UIImage(resource: .budWorkout) }
  static var budYoga: UIImage { UIImage(resource: .budYoga) }
  static var budHealthApp: UIImage { UIImage(resource: .budHealthApp) }
}
#endif

public extension ShapeStyle where Self == Color {
  // Sleep
  static var awakeSleep: Self { Color("AwakeSleep", bundle: BundleToken.bundle) }
  static var coreSleep: Self  { Color("CoreSleep", bundle: BundleToken.bundle) }
  static var deepSleep: Self  { Color("DeepSleep", bundle: BundleToken.bundle) }
  static var remSleep: Self   { Color("REMSleep", bundle: BundleToken.bundle) }
}

public extension Color {
  // Sleep
  static let awakeSleep = Color("AwakeSleep", bundle: BundleToken.bundle)
  static let coreSleep  = Color("CoreSleep", bundle: BundleToken.bundle)
  static let deepSleep  = Color("DeepSleep", bundle: BundleToken.bundle)
  static let remSleep   = Color("REMSleep", bundle: BundleToken.bundle)
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
