//
//  DSYMRecord.swift
//  Bloom-Backend
//

import Fluent
import Foundation

/// Where to find the debug symbols for one binary of one build.
///
/// The row is an index, not a store: the dSYM zip itself lives as a GitHub release asset, because
/// a Heroku dyno's disk does not survive a restart and Xcode Cloud ages its own artifacts out
/// sooner than a crash stops arriving.
///
/// Keyed by UUID because that is what actually identifies a binary. A build produces several - the
/// app, its frameworks, the watch app, each extension - and each has its own.
final class DSYMRecord: Model, @unchecked Sendable {
  static let schema = "dsyms"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "app")
  var app: String

  /// Uppercase, no dashes, as `dwarfdump --uuid` prints it.
  @Field(key: "uuid")
  var uuid: String

  @Field(key: "binary_name")
  var binaryName: String

  @OptionalField(key: "arch")
  var arch: String?

  @Field(key: "app_version")
  var appVersion: String

  @Field(key: "build_number")
  var buildNumber: String

  /// Where the zip holding this dSYM can be fetched from.
  @Field(key: "download_url")
  var downloadURL: String

  /// The `__TEXT` segment's vmaddr from the dSYM, hex.
  ///
  /// MetricKit gives an offset into the text segment rather than a runtime address, so the
  /// symbolicator needs this to turn one into the other without opening the dSYM first.
  @OptionalField(key: "text_vmaddr")
  var textVMAddr: String?

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  init() { }

  init(
    id: UUID? = nil,
    app: String,
    uuid: String,
    binaryName: String,
    arch: String?,
    appVersion: String,
    buildNumber: String,
    downloadURL: String,
    textVMAddr: String?
  ) {
    self.id = id
    self.app = app
    self.uuid = uuid
    self.binaryName = binaryName
    self.arch = arch
    self.appVersion = appVersion
    self.buildNumber = buildNumber
    self.downloadURL = downloadURL
    self.textVMAddr = textVMAddr
  }
}
