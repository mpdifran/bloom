//
//  ChatSourcesSheet.swift
//  Bloom
//

import SwiftUI
import SafariServices
import BloomModel
import BloomUI
import AppUI

/// Every page an answer drew on, with a way through to each.
///
/// Built from cards rather than a divider-separated list: Bloom's chat surfaces are rounded cards
/// (`ChatContextCell`, `ChatWorkoutPlanCell`) and a dense hairline list would read as a settings
/// screen dropped into the conversation.
struct ChatSourcesSheet: View {
  let sources: [SocketMessage.SourceRef]

  @Environment(\.dismiss) private var dismiss
  @State private var safariURL: URL?

  var body: some View {
    NavigationStack {
      BloomScrollView(spacing: 12, padding: [.vertical]) {
        ForEach(sources) { source in
          Button {
            safariURL = URL(string: source.url)
          } label: {
            ChatSourceRow(source: source)
          }
          .buttonStyle(.plain)
          .padding(.horizontal)
        }
      }
      .navigationTitle("Sources")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
            .bold()
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .fullScreenCover(item: $safariURL) { url in
      ChatSafariView(url: url)
        .ignoresSafeArea()
    }
  }
}

/// One source, laid out like `ChatContextCell`: a tinted band naming the site, then the detail.
private struct ChatSourceRow: View {
  let source: SocketMessage.SourceRef

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        ChatSourceFavicon(source: source, size: 20)

        Text(source.siteName)
          .font(.headline)
          .fontDesign(.rounded)
          .bold()

        Spacer(minLength: 0)

        DisclosureIndicator()
      }
      .padding(.horizontal)
      .padding(.vertical, 12)
      .background {
        Rectangle().fill(.background.tertiary)
      }

      VStack(alignment: .leading, spacing: 4) {
        if let title = source.title, title.isNotEmpty {
          Text(title)
            .font(.body)
            .fontDesign(.rounded)
            .fixedSize(horizontal: false, vertical: true)
            .horizontalAlignment(.leading)
        }

        Text(source.host)
          .font(.caption)
          .fontDesign(.rounded)
          .foregroundStyle(.secondary)

        if let published = source.publishedDate {
          Text(published, format: .dateTime.month(.abbreviated).day().year())
            .font(.caption)
            .fontDesign(.rounded)
            .foregroundStyle(.tertiary)
        }
      }
      .padding()
    }
    .chatCardContainer(includePadding: false)
  }
}

/// Links open in-app rather than bouncing out, so the conversation is still there afterwards.
struct ChatSafariView: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context: Context) -> SFSafariViewController {
    let controller = SFSafariViewController(url: url)
    controller.preferredControlTintColor = UIColor(ThemeController.shared.theme.color)
    return controller
  }

  func updateUIViewController(_ controller: SFSafariViewController, context: Context) { }
}

extension URL: @retroactive Identifiable {
  public var id: String { absoluteString }
}

#Preview("Sources sheet") {
  PreviewEnvironment {
    ChatSourcesSheet(
      sources: [
        .preview(siteName: "Tripadvisor", host: "tripadvisor.ca"),
        .preview(
          siteName: "OpenTable",
          host: "opentable.com",
          title: "The 10 Best Restaurants Near Me in Kitchener | OpenTable"
        ),
        .preview(siteName: "Yelp", host: "yelp.com", title: "Best Italian in Kitchener, ON"),
      ]
    )
  }
}
