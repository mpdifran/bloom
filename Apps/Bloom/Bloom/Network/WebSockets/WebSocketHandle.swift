//
//  WebSocketHandle.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Foundation
import BloomModel

final actor WebSocketHandle {
  let task: URLSessionWebSocketTask

  init(task: URLSessionWebSocketTask) {
    self.task = task
  }

  @AsyncStreamable var data: Data?

  private var hasStarted = false

  private let encoder = JSONEncoder.bloomModel
  private var observerTask: Task<Void, Error>?
  private var error: Error?

  deinit {
    observerTask?.cancel()
  }
}

extension WebSocketHandle {

  func start() async {
    self.observerTask = Task.detached { [weak self, task] in
      do {
        while true {
          let message = try await task.receive()
          switch message {
          case .string(let text):
            guard let data = text.data(using: .utf8) else { return }

            await self?.handle(data: data)
          case .data(let data):
            await self?.handle(data: data)
          @unknown default:
            print("WebSocketHandle: Received unknown message!")
          }
        }
      } catch {
        await self?.set(error: error)
      }
    }
    task.resume()
  }

  func send<T: Encodable>(payload: T) async throws {
    if !hasStarted {
      await start()
    }
    let data = try encoder.encode(payload)
    try await task.send(.data(data))
  }
}

private extension WebSocketHandle {

  func handle(data: Data) {
    self.data = data
  }

  func set(error: Error) {
    self.error = error
  }
}
