//
//  ChatDocumentCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-09-29.
//

import SwiftUI
import SFSafeSymbols

struct ChatDocumentCell: View {
  let document: ChatDocumentAttachment

  var body: some View {
    HStack {
      Spacer(minLength: 60)

      HStack(spacing: 12) {
        Image(systemSymbol: document.systemSymbol)
          .font(.title2)
          .foregroundStyle(.tint)
          .frame(square: 32)

        VStack(alignment: .leading, spacing: 2) {
          Text(verbatim: document.documentFilename)
            .font(.headline)
            .lineLimit(2)
            .truncationMode(.middle)
          Text(verbatim: document.formattedByteCount)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .fontDesign(.rounded)
      }
      .chatCardContainer()
      .padding(.horizontal)
    }
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      VStack {
        ChatDocumentCell(
          document: ChatDocumentAttachment(documentFilename: "Blood Work - March.pdf", documentByteCount: 482_133)
        )
        ChatDocumentCell(
          document: ChatDocumentAttachment(documentFilename: "meal-plan.xlsx", documentByteCount: 24_310)
        )
      }
      .padding()
    }
  }
}
