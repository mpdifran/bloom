//
//  ChatUnknownContentCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-02.
//

import SwiftUI

struct ChatUnknownContentCell: View {
  let showReportButton: Bool
  let responseID: String?
  let requestID: String?

  init(
    showReportButton: Bool = false,
    responseID: String? = nil,
    requestID: String? = nil
  ) {
    self.showReportButton = showReportButton
    self.responseID = responseID
    self.requestID = requestID
  }

  @State private var showReportSheet = false

  @Bindable private var themeController = ThemeController.shared

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        HStack {
          Image(systemSymbol: .exclamationmarkTriangleFill)
            .foregroundStyle(.white, .tint)
          Text("Unknown Content")
            .bold()
            .foregroundStyle(.tint)
          Spacer()
        }
        .cardContainer()
      }
      .padding(.horizontal)
      .tint(.mutedYellow)

      if showReportButton,
         responseID != nil,
         requestID != nil {
        Button("Report a Problem") {
          showReportSheet = true
        }
        .bold()
        .font(.caption)
        .padding(.horizontal)
        .padding(.horizontal)
      }
    }
    .sheet(isPresented: $showReportSheet) {
      if let responseID = responseID,
         let requestID = requestID {
        ChatReportReviewView(
          responseID: responseID,
          requestID: requestID
        )
        .environment(themeController)
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ChatUnknownContentCell()
    }
  }
}
