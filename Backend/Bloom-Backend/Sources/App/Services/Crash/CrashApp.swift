//
//  CrashApp.swift
//  Bloom-Backend
//

import Vapor

/// The apps allowed to report crashes.
///
/// An allow-list rather than a free-text column: the app arrives in the URL from a client whose
/// ingest key is compiled into a binary somebody else can read, so without this the table would
/// accept a row for any name a stranger cared to invent.
///
/// Extensions report as the app they ship in - they share its version and its dSYMs - and are told
/// apart by `CrashReport.processName`.
enum CrashApp: String, CaseIterable, Sendable {
  case bloom
  case bloomWatch = "bloom-watch"

  init(pathComponent: String) throws {
    guard let app = CrashApp(rawValue: pathComponent.lowercased()) else {
      // Deliberately not "unknown app": an endpoint that names what it does know is an endpoint
      // that enumerates it for you.
      throw Abort(.notFound)
    }
    self = app
  }

  init(request: Request) throws {
    try self.init(pathComponent: request.parameters.get("app") ?? "")
  }
}
