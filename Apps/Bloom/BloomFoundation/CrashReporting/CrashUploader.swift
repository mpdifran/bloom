//
//  CrashUploader.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation

/// Sends a crash report to the backend.
///
/// Its own session rather than CoreNetwork's, which BloomFoundation can't depend on. A default
/// session rather than a background one: this is a few kilobytes that can wait for the next launch if it has to, and a background session means
/// a delegate, an identifier and a relaunch path for no benefit at this size.
struct CrashUploader {

  let configuration: CrashReportingConfiguration
  let session: URLSession

  init(configuration: CrashReportingConfiguration, session: URLSession = .crashReporting) {
    self.configuration = configuration
    self.session = session
  }

  /// What to do with the report afterwards.
  enum Outcome: Equatable {
    /// Delivered, or recognised as one already delivered.
    case accepted
    /// Refused in a way that will never change - too large, malformed, a schema this backend
    /// does not know. Retrying forever is strictly worse than dropping it.
    case rejected(status: Int)
    /// Not delivered this time. Includes 404, which is what an undeployed backend and a
    /// refused ingest key both look like, so it has to stay retryable.
    case retryable
  }

  func upload(_ payload: CrashReportPayload) async -> Outcome {
    guard let baseURL = configuration.baseURL else { return .retryable }

    let url = baseURL
      .appendingPathComponent("v1")
      .appendingPathComponent("apps")
      .appendingPathComponent(configuration.app)
      .appendingPathComponent("crashes")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(configuration.ingestKey, forHTTPHeaderField: "X-Crash-Ingest-Key")

    do {
      request.httpBody = try CrashReportPayload.makeEncoder().encode(payload)
    } catch {
      // The payload cannot be encoded, so it will never be sendable.
      return .rejected(status: 0)
    }

    do {
      let (_, response) = try await session.data(for: request)
      guard let http = response as? HTTPURLResponse else { return .retryable }

      switch http.statusCode {
      case 200 ... 299:
        return .accepted
      case 400, 413, 422:
        return .rejected(status: http.statusCode)
      default:
        return .retryable
      }
    } catch {
      return .retryable
    }
  }
}

// MARK: - Session

extension URLSession {

  /// Waits for connectivity rather than failing the moment there is none - a phone that
  /// crashed on a plane still has the report when it lands.
  static let crashReporting: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.waitsForConnectivity = true
    configuration.timeoutIntervalForRequest = 15
    configuration.allowsCellularAccess = true

    return URLSession(configuration: configuration)
  }()
}
