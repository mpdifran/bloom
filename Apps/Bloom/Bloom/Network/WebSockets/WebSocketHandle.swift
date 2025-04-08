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
  @AsyncStreamable var hasDisconnected = false
  @AsyncStreamable var error: Error?

  private var hasStarted = false

  private var taskDelegate: TaskDelegate?

  private let encoder = JSONEncoder.bloomModel
  private var observerTask: Task<Void, Error>?
  private var pingTask: Task<Void, Never>?

  deinit {
    observerTask?.cancel()
    task.cancel(with: .normalClosure, reason: nil)
  }
}

extension WebSocketHandle {

  func start() async {
    guard !hasStarted else { return }
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
    taskDelegate = TaskDelegate { [weak self] (error) in
      await self?.markDisconnected(error: error)
    }
    task.delegate = taskDelegate
    task.resume()
    hasStarted = true

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

  func markDisconnected(error: Error?) {
    self.error = error
    hasDisconnected = true
    hasStarted = false
    pingTask?.cancel()
    pingTask = nil
  }

  func set(error: Error) {
    self.error = error
  }
}

extension WebSocketHandle {
  final class TaskDelegate: NSObject, URLSessionTaskDelegate {
    private let onComplete: @Sendable (Error?) async -> Void

    init(onComplete: @escaping @Sendable (Error?) async -> Void) {
      self.onComplete = onComplete

      super.init()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
      Task {
        await onComplete(error)
      }
    }
  }
}
