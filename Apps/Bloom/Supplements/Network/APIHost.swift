//
//  APIHost.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-05.
//

import SwiftUI

@MainActor
final class APIHost: ObservableObject {
  static let shared = APIHost()

  @AppStorage("APIHost.base", store: .group) var base: String = ""

  private init() { }
}

extension APIHost {

  var resolvedHost: URL {
    if let url = URL(string: base), base.isNotEmpty {
      return url
    }
    return URL(string: "https://bloom-api-5903aeb2ee43.herokuapp.com/")!
  }
}
