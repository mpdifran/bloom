//
//  FileLineReader.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-11.
//

import Foundation

public class FileLineReader {
   public let path: String

   fileprivate let file: UnsafeMutablePointer<FILE>!

   init?(path: String) {
      self.path = path
      file = fopen(path, "r")
      guard file != nil else { return nil }
   }

   public var nextLine: String? {
      var line: UnsafeMutablePointer<CChar>?
      var linecap: Int = 0
      defer { free(line) }
      return getline(&line, &linecap, file) > 0 ? String(cString: line!) : nil
   }

   deinit {
      fclose(file)
   }
}

extension FileLineReader: Sequence {
   public func makeIterator() -> AnyIterator<String> {
      return AnyIterator<String> {
         return self.nextLine
      }
   }
}
