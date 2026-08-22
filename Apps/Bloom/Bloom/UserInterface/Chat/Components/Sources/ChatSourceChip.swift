//
//  ChatSourceChip.swift
//  Bloom
//

import SwiftUI
import BloomModel
import BloomUI

/// A single citation, shown against the part of Bud's answer it supports.
///
/// Deliberately quiet: a citation is provenance, not a call to action, and a row of loud pills
/// would fight the message for attention. Sized off `.caption` so it sits inside the text block
/// rather than beside it.
struct ChatSourceChip: View {
  let source: SocketMessage.SourceRef
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      chip
    }
    .buttonStyle(.plain)
    .accessibilityLabel(Text(source.siteName))
    .accessibilityHint(Text("Opens this source"))
  }

  private var chip: some View {
    HStack(spacing: 5) {
      ChatSourceFavicon(source: source, size: 14)

      Text(source.siteName)
        .font(.caption)
        .fontDesign(.rounded)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background {
      Capsule().fill(.background.tertiary)
    }
    .contentShape(Capsule())
  }
}

/// The site's icon, or a lettered stand-in.
///
/// Most domains resolve to an icon eventually, but the first citation of a site arrives before one
/// has been fetched - and plenty of sites never have a usable one - so the fallback is the common
/// case often enough to be worth designing rather than leaving blank.
struct ChatSourceFavicon: View {
  let source: SocketMessage.SourceRef
  var size: CGFloat = 14

  private var initial: String {
    String(source.siteName.prefix(1)).uppercased()
  }

  var body: some View {
    Group {
      if let faviconURL = source.faviconURL, let url = URL(string: faviconURL) {
        AsyncImage(url: url) { image in
          image.resizable().aspectRatio(contentMode: .fit)
        } placeholder: {
          fallback
        }
      } else {
        fallback
      }
    }
    .frame(square: size)
    .clipShape(Circle())
    .overlay {
      // A hairline keeps a white favicon from dissolving into a light background.
      Circle().stroke(.fill, lineWidth: 0.5)
    }
  }

  private var fallback: some View {
    ZStack {
      Circle().fill(.fill.tertiary)
      Text(initial)
        .font(.system(size: size * 0.6, weight: .semibold, design: .rounded))
        .foregroundStyle(.secondary)
    }
  }
}

#Preview("Chip") {
  PreviewEnvironment {
    VStack(alignment: .leading, spacing: 12) {
      ChatSourceChip(source: .preview(siteName: "Tripadvisor", host: "tripadvisor.ca")) { }
      ChatSourceChip(source: .preview(siteName: "OpenTable", host: "opentable.com")) { }
    }
    .padding()
  }
}

extension SocketMessage.SourceRef {
  /// Fixture for previews only.
  static func preview(
    siteName: String,
    host: String,
    title: String = "THE 10 BEST Italian Restaurants in Kitchener (Updated 2026)"
  ) -> SocketMessage.SourceRef {
    SocketMessage.SourceRef(
      id: host,
      url: "https://\(host)/example",
      host: host,
      siteName: siteName,
      title: title,
      publishedDate: nil,
      faviconURL: nil,
      blockIndex: nil
    )
  }
}
