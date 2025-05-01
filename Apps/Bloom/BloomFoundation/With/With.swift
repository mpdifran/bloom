//
//  With.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

import Foundation

extension NSObject: With { }
extension URLRequest: With { }
extension CGRect: With { }
extension Dictionary: With { }
extension Array: With { }
extension Set: With { }

public protocol With { }

public extension With {

  @discardableResult
  @inline(__always)
  func with(_ populator: (inout Self) throws -> Void) rethrows -> Self {
    var with = self
    try populator(&with)
    return with
  }

  @discardableResult
  @inline(__always)
  func with<T>(_ property: WritableKeyPath<Self, T>, _ value: T) -> Self {
    var with = self
    with[keyPath: property] = value
    return with
  }
}

public protocol WithInit: With {
  init()
}

public extension WithInit {
  static func with(_ populator: (inout Self) throws -> Void) rethrows -> Self {
    var instance = Self()
    try populator(&instance)
    return instance
  }

  static func with<T>(_ property: WritableKeyPath<Self, T>, _ value: T) -> Self {
    var with = Self()
    with[keyPath: property] = value
    return with
  }
}
