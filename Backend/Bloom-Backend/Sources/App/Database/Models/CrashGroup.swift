//
//  CrashGroup.swift
//  Bloom-Backend
//

import Fluent
import Foundation

/// Crashes from one app that share a signature.
///
/// There is no stored occurrence count. A report is regrouped once it has been symbolicated - the
/// signature it arrives with is coarse, because an unsymbolicated frame is an address and nothing
/// else - so a counter kept by hand would drift every time one moved. The count is a `COUNT(*)`
/// over the reports instead.
final class CrashGroup: Model, @unchecked Sendable {
  static let schema = "crash_groups"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "app")
  var app: String

  @Field(key: "signature")
  var signature: String

  @Field(key: "title")
  var title: String

  @Field(key: "severity")
  var severity: String

  @Field(key: "affected_versions")
  var affectedVersions: [String]

  @Field(key: "first_seen_version")
  var firstSeenVersion: String

  @Field(key: "last_seen_version")
  var lastSeenVersion: String

  @OptionalField(key: "fix_pr_url")
  var fixPRUrl: String?

  /// "pr_open", "fixed", "unfixable" or "manual"; nil or anything else means nobody has claimed it.
  @OptionalField(key: "fix_status")
  var fixStatus: String?

  /// What the daily triage made of this group, kept so it isn't re-analysed every day.
  @OptionalField(key: "analysis")
  var analysis: String?

  @Field(key: "is_third_party")
  var isThirdParty: Bool

  @OptionalField(key: "last_seen_at")
  var lastSeenAt: Date?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  @Timestamp(key: "updated_at", on: .update)
  var updatedAt: Date?

  init() { }

  init(
    id: UUID? = nil,
    app: String,
    signature: String,
    title: String,
    severity: String,
    affectedVersions: [String],
    firstSeenVersion: String,
    lastSeenVersion: String,
    isThirdParty: Bool = false
  ) {
    self.id = id
    self.app = app
    self.signature = signature
    self.title = title
    self.severity = severity
    self.affectedVersions = affectedVersions
    self.firstSeenVersion = firstSeenVersion
    self.lastSeenVersion = lastSeenVersion
    self.fixPRUrl = nil
    self.fixStatus = nil
    self.analysis = nil
    self.isThirdParty = isThirdParty
    self.lastSeenAt = nil
  }
}
