//
//  SocketMessage+Namespace.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-01.
//

public enum SocketMessage { }

public extension SocketMessage {
  /// What this build of the chat protocol understands.
  ///
  /// Lives here, shared by client and server, so the two cannot drift: the client sends it and the
  /// server gates on it, and a constant defined twice would eventually be bumped once.
  ///
  /// Raise it only when a client gains a capability the server needs to know about *before*
  /// sending something. It is not an app version and should move far less often.
  ///
  /// - 0 (absent): clients from before this existed. Must keep working indefinitely.
  /// - 1: can render ``SocketMessage/SourceRef``, so may be sent web search results.
  static let currentProtocolVersion = 1
}
