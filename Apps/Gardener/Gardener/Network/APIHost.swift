//
//  APIHost.swift
//  Gardener
//
//  Created by Zach Radford on 2025-01-19.
//

import SwiftUI

final class APIHost: ObservableObject {
  static let shared = APIHost()

  @AppStorage("APIHost.overrideEnabled") var overrideEnabled: Bool = false
  @AppStorage("APIHost.override") var overrideBase: String = ""
}

extension APIHost {

  var base: URL {
    if let url = URL(string: overrideBase), overrideBase.isNotEmpty, overrideEnabled {
      return url
    } else {
      return URL(string: "https://api.trybloom.app/")!
    }
  }
}
