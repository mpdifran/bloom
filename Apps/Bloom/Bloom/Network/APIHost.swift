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

  @AppStorage("APIHost.overrideEnabled", store: .group) var overrideEnabled: Bool = false
  @AppStorage("APIHost.base", store: .group) var base: String = ""
  @AppStorage("APIHost.wsBase", store: .group) var wsBase: String = ""

  private init() { }
}

extension APIHost {

  var resolvedHost: URL {
    if let url = URL(string: base), base.isNotEmpty, overrideEnabled {
      return url
    }
    guard let urlString = Bundle.main.infoDictionary?["BLOOM_BASE_URL"] as? String else {
      fatalError("No base URL set.")
    }

    return URL(string: urlString.replacingOccurrences(of: "\\", with: ""))!
  }

  var resolvedWebSocketHost: URL {
    if let url = URL(string: wsBase), wsBase.isNotEmpty, overrideEnabled {
      return url
    }
    guard let urlString = Bundle.main.infoDictionary?["BLOOM_BASE_WS_URL"] as? String else {
      fatalError("No WebSocket base URL set.")
    }

    return URL(string: urlString.replacingOccurrences(of: "\\", with: ""))!
  }
}
