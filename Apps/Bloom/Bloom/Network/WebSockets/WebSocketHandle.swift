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
  private var pingTask: Task<Void, Never>?
  private var error: Error?

  deinit {
    observerTask?.cancel()
    task.cancel(with: .normalClosure, reason: nil)
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

    self.pingTask = schedulePing()
  }

  func stop() {
    task.cancel(with: .normalClosure, reason: nil)
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

  func schedulePing() -> Task<Void, Never> {
    Task {
      while !Task.isCancelled {
        do {
          await Delay(20_000)
          try await self.sendPing()
        } catch {
          print("Ping error: \(error)")
        }
      }
    }
  }

  func sendPing() async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      print("WebSocketHandle: Sending ping")
      task.sendPing { error in
        if let error = error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: ())
        }
      }
    }
  }

  func handle(data: Data) {
    self.data = data
  }

  func set(error: Error) {
    self.error = error
  }
}
