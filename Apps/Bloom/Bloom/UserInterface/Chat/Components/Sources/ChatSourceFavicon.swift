//
//  ChatSourceFavicon.swift
//  Bloom
//

import SwiftUI
import BloomModel
import BloomUI

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
      faviconURL: nil
    )
  }
}
