//
//  RemoteNotificationString.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-08-14.
//

import Foundation

/// Strings the backend sends as APNs `loc-key`, rather than as literal text.
///
/// iOS resolves a `loc-key` against this app's String Catalog in the user's language, so a remote
/// notification is localized without the server knowing anything about locale - and without the
/// notification text being duplicated server-side.
///
/// Nothing calls these at runtime. They exist so the compiler extracts the keys into the catalog and
/// keeps them translated: a key the server sends but the catalog doesn't contain is displayed to the
/// user verbatim, e.g. "notification.issueReportAccepted.title". Deleting an entry here silently
/// breaks the corresponding push, so keep them in step with NotificationService on the backend.
enum RemoteNotificationString {

  static let issueReportAcceptedTitle = String(
    localized: "notification.issueReportAccepted.title",
    defaultValue: "Thanks for your help!",
    comment: "Push notification title, sent when a user's correction to a food item is accepted"
  )

  static let issueReportAcceptedBody = String(
    localized: "notification.issueReportAccepted.body",
    defaultValue: "Your suggestions for %@ look great, thanks for helping improve Bloom!",
    comment: "Push notification body. The placeholder is the name of the food item the user corrected."
  )
}
