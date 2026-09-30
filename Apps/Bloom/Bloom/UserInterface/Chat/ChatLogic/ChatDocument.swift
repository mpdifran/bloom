//
//  ChatDocument.swift
//  Bloom
//
//  Created by Mark DiFranco on 2026-09-29.
//

import UIKit
import UniformTypeIdentifiers
import SFSafeSymbols
import BloomModel

/// A non-image file attached to a chat message that hasn't been sent yet.
struct ChatDocument: Identifiable, Hashable, Sendable {
  let id = UUID()
  let filename: String
  let data: Data

  var attachment: ChatDocumentAttachment {
    ChatDocumentAttachment(documentFilename: filename, documentByteCount: data.count)
  }
}

/// What chat history keeps of a sent document: enough to show it, not the file itself.
///
/// Stored as a message's rich content, so its keys must not overlap with any other rich content
/// type - they're told apart by which one decodes.
struct ChatDocumentAttachment: Codable, Hashable, Sendable {
  let documentFilename: String
  let documentByteCount: Int

  var formattedByteCount: String {
    ByteCountFormatter.string(fromByteCount: Int64(documentByteCount), countStyle: .file)
  }

  var systemSymbol: SFSymbol {
    ChatDocumentAttachment.systemSymbol(forFilename: documentFilename)
  }

  static func systemSymbol(forFilename filename: String) -> SFSymbol {
    let type = UTType(filenameExtension: (filename as NSString).pathExtension)
    if type?.conforms(to: .pdf) == true {
      return .richtextPage
    } else if type?.conforms(to: .spreadsheet) == true || type?.conforms(to: .commaSeparatedText) == true {
      return .tablecells
    } else if type?.conforms(to: .presentation) == true {
      return .rectangleOnRectangleAngled
    } else if type?.conforms(to: .sourceCode) == true {
      return .chevronLeftForwardslashChevronRight
    } else {
      return .textDocument
    }
  }
}

/// Sorts files picked from the Files app into images and documents, turning away the ones the
/// model can't read or that don't fit.
enum ChatAttachmentLoader {

  struct Result {
    var images = [UIImage]()
    var documents = [ChatDocument]()
    var unsupportedFilenames = [String]()
    var oversizedFilenames = [String]()

    var error: ChatAttachmentError? {
      guard unsupportedFilenames.isNotEmpty || oversizedFilenames.isNotEmpty else { return nil }
      return ChatAttachmentError(
        unsupportedFilenames: unsupportedFilenames,
        oversizedFilenames: oversizedFilenames
      )
    }
  }

  /// - Parameters:
  ///   - urls: Files to load, in the order they were picked.
  ///   - remainingCount: How many more attachments fit on the message.
  ///   - existingDocumentBytes: Size of the documents already attached, which count towards the
  ///     combined limit.
  static func load(urls: [URL], remainingCount: Int, existingDocumentBytes: Int) -> Result {
    var result = Result()
    var documentBytes = existingDocumentBytes

    for url in urls.prefix(remainingCount) {
      let filename = url.lastPathComponent
      guard let data = try? Data(contentsOf: url) else {
        result.unsupportedFilenames.append(filename)
        continue
      }

      if UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) == true {
        if let image = UIImage(data: data) {
          result.images.append(image)
        } else {
          result.unsupportedFilenames.append(filename)
        }
        continue
      }

      guard ChatUploadDocumentRequest.isSupported(filename: filename) else {
        result.unsupportedFilenames.append(filename)
        continue
      }
      guard data.count <= ChatUploadDocumentRequest.maxDocumentBytes,
            documentBytes + data.count <= ChatUploadDocumentRequest.maxTotalBytes else {
        result.oversizedFilenames.append(filename)
        continue
      }

      documentBytes += data.count
      result.documents.append(ChatDocument(filename: filename, data: data))
    }

    return result
  }
}

struct ChatAttachmentError: LocalizedError {
  let unsupportedFilenames: [String]
  let oversizedFilenames: [String]

  var errorDescription: String? {
    var lines = [String]()
    if unsupportedFilenames.isNotEmpty {
      let names = unsupportedFilenames.formatted(.list(type: .and))
      lines.append(String(
        localized: "Bud can't read \(names). Try a PDF, document, spreadsheet, or text file.",
        comment: "Shown when files attached to a chat message are of a type the assistant can't read. The argument is a list of filenames."
      ))
    }
    if oversizedFilenames.isNotEmpty {
      let names = oversizedFilenames.formatted(.list(type: .and))
      lines.append(String(
        localized: "\(names) is too large to attach.",
        comment: "Shown when files attached to a chat message exceed the size limit. The argument is a list of filenames."
      ))
    }
    return lines.joined(separator: "\n\n")
  }
}
