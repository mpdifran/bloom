//
//  SwiftData_ReproApp.swift
//  SwiftData-Repro
//
//  Created by Zach Radford on 2025-03-24.
//

import SwiftUI
import SwiftData

@main
struct SwiftData_ReproApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(ContainerHolder.shared.container)
  }
}
