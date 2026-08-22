//
//  ChatSourcesFooter.swift
//  Bloom
//

import SwiftUI
import BloomModel
import BloomUI

/// The "Sources" affordance under an assistant message.
///
/// Overlapping icons rather than a list of names: the point is to signal *that* the answer is
/// sourced and offer a way in, not to be read. Weighted to match the neighbouring Copy and Report
/// a Problem controls, because it belongs to that row rather than competing with the message.
struct ChatSourcesFooter: View {
  let sources: [SocketMessage.SourceRef]
  let action: () -> Void

  /// Beyond three the stack stops reading as a stack and starts reading as clutter.
  private var visible: [SocketMessage.SourceRef] {
    Array(sources.prefix(3))
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        HStack(spacing: -6) {
          ForEach(visible) { source in
            ChatSourceFavicon(source: source, size: 16)
              .overlay {
                // Stroked in the message background so overlapping icons stay distinct instead of
                // blurring into one shape.
                Circle().stroke(Color(.systemBackground), lineWidth: 1.5)
              }
          }
        }

        Text("Sources")
          .font(.caption)
          .fontDesign(.rounded)
          .bold()
      }
    }
    .buttonStyle(.plain)
    .foregroundStyle(.secondary)
    .accessibilityLabel(Text("Sources"))
    .accessibilityHint(Text("Shows the web pages this answer used"))
  }
}

#Preview("Footer") {
  PreviewEnvironment {
    VStack(alignment: .leading) {
      Text("Here are a few good Italian places nearby.")
        .padding(.horizontal, 15)

      ChatSourcesFooter(
        sources: [
          .preview(siteName: "Tripadvisor", host: "tripadvisor.ca"),
          .preview(siteName: "OpenTable", host: "opentable.com"),
          .preview(siteName: "Yelp", host: "yelp.com"),
        ],
        action: { }
      )
      .padding(.horizontal, 15)
    }
  }
}
