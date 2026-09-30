//
//  CrashReport+Migrations.swift
//  Bloom-Backend
//

import Fluent
import SQLKit

extension CrashReport {
  /// Crash reports, the groups they fall into, and the dSYM index the symbolicator reads.
  struct Create: AsyncMigration {
    func prepare(on database: any Database) async throws {
      try await database.schema(CrashGroup.schema)
        .id()
        .field("app", .string, .required)
        .field("signature", .string, .required)
        .field("title", .string, .required)
        .field("severity", .string, .required)
        .field("affected_versions", .array(of: .string), .required)
        .field("first_seen_version", .string, .required)
        .field("last_seen_version", .string, .required)
        .field("fix_pr_url", .string)
        .field("fix_status", .string)
        .field("analysis", .string)
        .field("is_third_party", .bool, .required)
        .field("last_seen_at", .datetime)
        .field("created_at", .datetime)
        .field("updated_at", .datetime)
        // Per app: the iOS app and the watch app crashing in the same system call are two bugs.
        .unique(on: "app", "signature")
        .create()

      try await database.schema(CrashReport.schema)
        .id()
        .field("app", .string, .required)
        .field("install_id", .string, .required)
        .field("source", .string, .required)
        .field("dedupe_key", .string)
        .field("app_version", .string, .required)
        .field("build_number", .string, .required)
        .field("os_version", .string, .required)
        .field("device_model", .string, .required)
        .field("process_name", .string)
        .field("exception_type", .string, .required)
        .field("exception_code", .string)
        .field("signal_name", .string)
        .field("termination_reason", .string)
        .field("crash_thread", .string, .required)
        .field("stack_trace", .string, .required)
        .field("symbolicated_trace", .string)
        .field("crash_group_id", .uuid, .references(CrashGroup.schema, "id", onDelete: .setNull))
        .field("raw_report", .string)
        .field("binary_images", .json)
        .field("frames", .json)
        .field("schema_version", .int, .required)
        .field("is_symbolicated", .bool, .required)
        .field("crashed_at", .datetime, .required)
        .field("created_at", .datetime)
        .create()

      try await database.schema(DSYMRecord.schema)
        .id()
        .field("app", .string, .required)
        .field("uuid", .string, .required)
        .field("binary_name", .string, .required)
        .field("arch", .string)
        .field("app_version", .string, .required)
        .field("build_number", .string, .required)
        .field("download_url", .string, .required)
        .field("text_vmaddr", .string)
        .field("created_at", .datetime)
        // The whole point of the table: one row per binary, found by UUID.
        .unique(on: "uuid")
        .create()

      guard let sql = database as? any SQLDatabase else { return }
      // The rate-limit probe and the dedupe probe, which run on every submission.
      try await sql.raw("CREATE INDEX idx_crash_reports_install ON crash_reports(app, install_id, created_at)").run()
      try await sql.raw("CREATE INDEX idx_crash_reports_dedupe ON crash_reports(app, dedupe_key, created_at)").run()
      // The symbolication worklist.
      try await sql.raw("CREATE INDEX idx_crash_reports_unsymbolicated ON crash_reports(app, is_symbolicated)").run()
      try await sql.raw("CREATE INDEX idx_crash_reports_group ON crash_reports(crash_group_id)").run()
      try await sql.raw("CREATE INDEX idx_crash_reports_created_at ON crash_reports(created_at)").run()
      try await sql.raw("CREATE INDEX idx_dsyms_build ON dsyms(app, build_number)").run()
    }

    func revert(on database: any Database) async throws {
      try await database.schema(DSYMRecord.schema).delete()
      try await database.schema(CrashReport.schema).delete()
      try await database.schema(CrashGroup.schema).delete()
    }
  }
}
