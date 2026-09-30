//
//  EditableChatDocumentCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-09-29.
//

import SwiftUI
import SFSafeSymbols

struct EditableChatDocumentCell: View {
  let document: ChatDocument
  let onRemove: () -> Void

  var body: some View {
    HStack {
      Image(systemSymbol: document.attachment.systemSymbol)
      VStack(alignment: .leading, spacing: 0) {
        Text(verbatim: document.filename)
          .fontWeight(.heavy)
          .lineLimit(1)
          .truncationMode(.middle)
        Text(verbatim: document.attachment.formattedByteCount)
          .foregroundStyle(.secondary)
      }
    }
    .font(.caption)
    .frame(height: 50)
    .padding(.horizontal)
    .frame(minWidth: 0, maxWidth: 160)
    .background {
      RoundedRectangle(cornerRadius: 10)
        .fill(.background)
    }
    .overlay {
      Button {
        onRemove()
      } label: {
        Image(systemSymbol: .xmarkCircleFill)
          .foregroundStyle(.tint, .background.tertiary)
          .frame(square: 30)
      }
      .offset(x: 10, y: -10)
      .zStackAlignment(.topTrailing)
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      EditableChatDocumentCell(
        document: ChatDocument(filename: "Blood Work - March.pdf", data: Data(count: 482_133))
      ) {

      }
    }
  }
}
