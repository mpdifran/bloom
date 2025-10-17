//
//  NetworkMonitor.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-06.
//

import Foundation
import Network

@MainActor
public final class NetworkMonitor {

  public private(set) var isNetworkReachable = true

  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "NetworkMonitor.queue")

  public init() {
    monitor.pathUpdateHandler = { [weak self] (path) in
      guard let self = self else { return }

      Task { @MainActor in
        self.handle(path: path)
      }
    }

    monitor.start(queue: queue)
  }

  deinit {
    monitor.cancel()
  }
}

private extension NetworkMonitor {

  func handle(path: NWPath) {
    switch path.status {
    case .satisfied:
      isNetworkReachable = true
      print("Network Reachable")
    default:
      isNetworkReachable = false
      print("Network Not Reachable")
    }
  }
}
