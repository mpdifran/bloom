//
//  FileHandle+Helpers.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-04.
//

import Foundation

extension FileHandle {

  static func read(from url: URL, handler: (FileHandle) async throws -> Void) async throws {
    let fileHandle = try FileHandle(forReadingFrom: url)
    defer { try? fileHandle.close() }

    try await handler(fileHandle)
  }

  static func readFileLines(from fileURL: URL, processLine: (String) async throws -> Bool) async throws {
    try await read(from: fileURL) { fileHandle in
      let chunkSize = 1_048_576
      var leftover = Data()

      while let chunk = try fileHandle.read(upToCount: chunkSize) {
        let data = leftover + chunk
        let components = data.split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: false)
        let completeLines = components.dropLast()
        leftover = components.last.map { Data($0) } ?? Data()

        for lineData in completeLines {
          if let line = String(data: lineData, encoding: .utf8) {
            if try await processLine(line) == false {
              return
            }
          }
        }
      }

      // Process any leftover data as the final line
      if !leftover.isEmpty, let lastLine = String(data: leftover, encoding: .utf8) {
        _ = try await processLine(lastLine)
      }
    }
  }
}
