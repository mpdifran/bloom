//
//  SocketMessage+UserLocation.swift
//  bloom-model
//

import Foundation

public extension SocketMessage {
  /// Roughly where the user is, so a web search can return results from the right place.
  ///
  /// City is as precise as this ever gets. The coordinates behind it never leave the device - the
  /// client reverse-geocodes and sends only the placemark - and the search API is told explicitly
  /// that the fix is approximate.
  ///
  /// Only populated when the user has turned on the location category in AI data sharing. Absent
  /// otherwise, and absent from clients that predate it, so `nil` has to keep meaning "don't
  /// localize the search" indefinitely.
  struct UserLocation: Codable, Hashable, Sendable {
    /// City or locality, e.g. "Kitchener". Never a street, postal code or coordinate.
    public let city: String?
    /// State or province, e.g. "Ontario".
    public let region: String?
    /// ISO 3166-1 alpha-2, e.g. "CA".
    public let country: String?
    /// IANA identifier, e.g. "America/Toronto". Comes from the device rather than the placemark,
    /// so it is present even when geocoding fails.
    public let timezone: String?

    /// Nothing to send when every field is empty - the difference between "no consent" and "consent
    /// but no fix" doesn't matter to the search, and an empty object would just be noise.
    public var isEmpty: Bool {
      city == nil && region == nil && country == nil && timezone == nil
    }

    public init(
      city: String? = nil,
      region: String? = nil,
      country: String? = nil,
      timezone: String? = nil
    ) {
      self.city = city
      self.region = region
      self.country = country
      self.timezone = timezone
    }
  }
}
