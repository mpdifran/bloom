//
//  ChatUploadDocumentRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation

/// Non-image files attached to a chat message. Images keep going through ``ChatUploadFileRequest``
/// so they're resized and sent to the model as images; everything else is passed as a file input.
public struct ChatUploadDocumentRequest: Codable, Equatable, Sendable {
  public let documents: [Document]

  public init(documents: [Document]) {
    self.documents = documents
  }

  public struct Document: Codable, Equatable, Sendable {
    /// The original filename, extension included. The model uses the extension to decide how to
    /// read the file, so it has to survive the upload.
    public let filename: String
    public let data: Data

    public init(filename: String, data: Data) {
      self.filename = filename
      self.data = data
    }
  }

  /// Max size of a single document (bytes).
  public static let maxDocumentBytes = 20 * 1024 * 1024
  /// Max combined size of the documents in one request (bytes). OpenAI caps a single request's
  /// file inputs at 50 MB, so this leaves headroom for the images sent alongside.
  public static let maxTotalBytes = 40 * 1024 * 1024

  /// File extensions the model can read as a file input.
  public static let supportedFileExtensions: Set<String> = [
    // PDF
    "pdf",
    // Spreadsheets
    "xla", "xlb", "xlc", "xlm", "xls", "xlsx", "xlt", "xlw", "csv", "tsv", "iif",
    // Rich documents
    "doc", "docx", "dot", "odt", "rtf",
    // Presentations
    "pot", "ppa", "pps", "ppt", "pptx", "pwz", "wiz",
    // Text and code
    "asm", "bat", "c", "cc", "conf", "cpp", "css", "cxx", "def", "dic", "eml", "h", "hh", "htm",
    "html", "ics", "ifb", "in", "js", "json", "ksh", "list", "log", "markdown", "md", "mht",
    "mhtml", "mime", "mjs", "nws", "pl", "py", "rst", "s", "sql", "srt", "text", "txt", "vcf",
    "vtt", "xml"
  ]

  public static func isSupported(filename: String) -> Bool {
    let fileExtension = (filename as NSString).pathExtension.lowercased()
    return supportedFileExtensions.contains(fileExtension)
  }
}
