//
//  CrashReport.swift
//  Bloom-Backend
//

import Fluent
import Foundation

/// One crash, as a device reported it.
///
/// Ported from Northstar's `AppCrashReport`, which AirChat reports into. The image fields are the
/// point: with the UUID of each loaded binary and the address it was loaded at, `atos -l` resolves
/// a frame properly and a dSYM is matched by UUID instead of being guessed at from a build number.
final class CrashReport: Model, @unchecked Sendable {
  static let schema = "crash_reports"

  @ID(key: .id)
  var id: UUID?

  /// Which app this came from. See `CrashApp`.
  @Field(key: "app")
  var app: String

  /// Identifies the install, not the person.
  ///
  /// Deliberately not the user's ID: sending that would make crashes linked to a user, and the
  /// App Store privacy answer would have to say so. This is a UUID made on first launch and kept
  /// locally, so a crash loop can be rate limited without knowing who anyone is.
  @Field(key: "install_id")
  var installID: String

  /// Which capture path produced this: "signal", "nsexception" or "metrickit". The same crash
  /// can arrive from two of them; see `dedupeKey`.
  @Field(key: "source")
  var source: String

  /// Stable across capture paths for one crash, so the second arrival can be dropped.
  @OptionalField(key: "dedupe_key")
  var dedupeKey: String?

  @Field(key: "app_version")
  var appVersion: String

  @Field(key: "build_number")
  var buildNumber: String

  @Field(key: "os_version")
  var osVersion: String

  @Field(key: "device_model")
  var deviceModel: String

  /// The process that crashed - the app itself, or one of its extensions.
  @OptionalField(key: "process_name")
  var processName: String?

  @Field(key: "exception_type")
  var exceptionType: String

  @OptionalField(key: "exception_code")
  var exceptionCode: String?

  @OptionalField(key: "signal_name")
  var signalName: String?

  @OptionalField(key: "termination_reason")
  var terminationReason: String?

  @Field(key: "crash_thread")
  var crashThread: String

  /// The stack rendered in Apple's `.crash` frame format, which is what the symbolicate script
  /// reads.
  @Field(key: "stack_trace")
  var stackTrace: String

  @OptionalField(key: "symbolicated_trace")
  var symbolicatedTrace: String?

  @OptionalField(key: "crash_group_id")
  var crashGroupID: UUID?

  @OptionalField(key: "raw_report")
  var rawReport: String?

  /// Every binary loaded at crash time, with its UUID and load address.
  ///
  /// Held in a wrapper because Fluent maps a bare Swift array onto a Postgres *array* column -
  /// `jsonb[]` - and the column is a single `jsonb` document.
  @OptionalField(key: "binary_images")
  var storedBinaryImages: CrashBinaryImageList?

  /// The crashing thread's frames, structured. `stackTrace` is the same thing rendered.
  @OptionalField(key: "frames")
  var storedFrames: CrashFrameList?

  var binaryImages: [CrashBinaryImage]? {
    get { storedBinaryImages?.images }
    set { storedBinaryImages = newValue.map(CrashBinaryImageList.init(images:)) }
  }

  var frames: [CrashFrame]? {
    get { storedFrames?.frames }
    set { storedFrames = newValue.map(CrashFrameList.init(frames:)) }
  }

  @Field(key: "schema_version")
  var schemaVersion: Int

  @Field(key: "is_symbolicated")
  var isSymbolicated: Bool

  @Field(key: "crashed_at")
  var crashedAt: Date

  @Timestamp(key: "created_at", on: .create)
  var createdAt: Date?

  init() { }

  init(
    id: UUID? = nil,
    app: String,
    installID: String,
    source: String,
    dedupeKey: String?,
    appVersion: String,
    buildNumber: String,
    osVersion: String,
    deviceModel: String,
    processName: String? = nil,
    exceptionType: String,
    exceptionCode: String? = nil,
    signalName: String? = nil,
    terminationReason: String? = nil,
    crashThread: String,
    stackTrace: String,
    rawReport: String? = nil,
    binaryImages: [CrashBinaryImage]? = nil,
    frames: [CrashFrame]? = nil,
    schemaVersion: Int,
    crashedAt: Date
  ) {
    self.id = id
    self.app = app
    self.installID = installID
    self.source = source
    self.dedupeKey = dedupeKey
    self.appVersion = appVersion
    self.buildNumber = buildNumber
    self.osVersion = osVersion
    self.deviceModel = deviceModel
    self.processName = processName
    self.exceptionType = exceptionType
    self.exceptionCode = exceptionCode
    self.signalName = signalName
    self.terminationReason = terminationReason
    self.crashThread = crashThread
    self.stackTrace = stackTrace
    self.symbolicatedTrace = nil
    self.crashGroupID = nil
    self.rawReport = rawReport
    self.storedBinaryImages = binaryImages.map(CrashBinaryImageList.init(images:))
    self.storedFrames = frames.map(CrashFrameList.init(frames:))
    self.schemaVersion = schemaVersion
    self.isSymbolicated = false
    self.crashedAt = crashedAt
  }
}

// MARK: - Stored JSON

/// Wrappers so each column holds one JSON document rather than a Postgres array of them.
struct CrashBinaryImageList: Codable, Sendable {
  let images: [CrashBinaryImage]
}

struct CrashFrameList: Codable, Sendable {
  let frames: [CrashFrame]
}

/// One loaded binary, as the client saw it at crash time.
struct CrashBinaryImage: Codable, Sendable {
  let name: String
  /// Uppercase, no dashes - the form `dwarfdump --uuid` prints, so a dSYM row matches on it.
  let uuid: String
  /// Hex, e.g. "0x1023f4000". What `atos -l` wants.
  let loadAddress: String
  let slide: Int?
  let arch: String?
  let isMainExecutable: Bool

  /// Whether the binary belongs to the app rather than the system. Only the client can tell,
  /// and grouping is useless without it - see `CrashGrouping`.
  let isAppImage: Bool?
}

/// One frame of the crashing thread.
struct CrashFrame: Codable, Sendable {
  let index: Int
  let imageName: String?
  let imageUUID: String?
  /// Hex. Absolute where the client had it; MetricKit reports offsets only.
  let address: String?
  /// Distance into the image's text segment. Stable across launches, unlike `address`.
  let offset: Int?
  /// Set only where the client already knew it, e.g. `NSException.callStackSymbols`.
  let symbol: String?
}
