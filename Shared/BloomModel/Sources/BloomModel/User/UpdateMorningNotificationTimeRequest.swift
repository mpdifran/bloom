//
//  UpdateMorningNotificationTimeRequest.swift
//  bloom-model
//
//  Created by Assistant on 2025-07-27.
//

public struct UpdateMorningNotificationTimeRequest: Codable {
  /// 0-23
  public let hour: Int
  /// 0-59 (will be rounded to nearest 5)
  public let minute: Int
  /// IANA timezone identifier, e.g., "America/New_York"
  public let timeZone: String

  public init(hour: Int, minute: Int, timeZone: String) {
    self.hour = hour
    self.minute = minute
    self.timeZone = timeZone
  }
}
