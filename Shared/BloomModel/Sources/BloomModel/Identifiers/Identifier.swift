//
//  Identifier.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-12-01.
//

import Foundation

// MARK: - Identifier

/// An identifier class meant to be subclassed. Once subclassed, it can provide type safety when dealing with identifiers.
///
/// ```
/// final class PeerIdentifier: Identifier { }
/// ```
///
/// - note: When dealing with Codable objects, mark your subclass as ``Codable``.
open class Identifier: NSObject {

  /// The underlaying value of the identifier.
  public let value: String

  /// Default init. Uses the value of a new ``UUID`` to create an ``Identifier``.
  public convenience override init() {
    self.init(UUID().uuidString)
  }

  /// Initialies the ``Identifier`` with a ``String`` value.
  public init(_ value: String) {
    self.value = value
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    self.value = try values.decode(String.self, forKey: .value)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(value, forKey: .value)
  }

  enum CodingKeys: String, CodingKey {
    case value
  }
}

extension Identifier {

  public static func == (lhs: Identifier, rhs: Identifier) -> Bool {
    lhs.value == rhs.value
  }
}
