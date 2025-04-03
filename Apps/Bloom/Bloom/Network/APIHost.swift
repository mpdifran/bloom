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

  private init() { }
}

extension APIHost {

  var resolvedHost: URL {
    if let url = URL(string: base), base.isNotEmpty, overrideEnabled {
      return url
    }
    return URL(string: "https://bloom-api-5903aeb2ee43.herokuapp.com/")!
  }

  var resolvedWebSocketHost: URL {
    let webSocketBase = base.replacingOccurrences(of: "https://", with: "wss://")
    if let url = URL(string: webSocketBase), webSocketBase.isNotEmpty, overrideEnabled {
      return url
    }
    return URL(string: "wss://bloom-api-5903aeb2ee43.herokuapp.com/")!
  }
}
