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

  var base: String {
    if overrideBase.isNotEmpty, overrideEnabled {
      return overrideBase
    } else {
      return "https://bloom-api-5903aeb2ee43.herokuapp.com/"
    }
  }
}
