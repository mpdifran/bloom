//
//  BinaryImageTable.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation
import MachO

/// Every binary loaded into this process, with the UUID and address a symbolicator needs.
///
/// Built once at install, before any handler is armed, and written straight to disk. None of this
/// is safe to do while a process is crashing - it reads mach headers, allocates, and builds
/// strings - which is exactly why it happens up front and the handler only writes addresses.
///
/// The UUID is what lets a dSYM be found later, and the load address is what makes the addresses
/// mean anything: the kernel slides every image by a different amount on every launch.
struct BinaryImageTable: Codable, Sendable {

  let images: [CrashReportPayload.BinaryImage]

  /// Where each image starts and ends, so a raw address can be attributed to one.
  let ranges: [ImageRange]

  struct ImageRange: Codable, Sendable {
    let uuid: String
    let name: String
    let start: UInt64
    /// Nil where the text segment couldn't be read.
    let size: UInt64?
  }
}

// MARK: - Reading dyld

extension BinaryImageTable {

  static func current() -> BinaryImageTable {
    var images = [CrashReportPayload.BinaryImage]()
    var ranges = [ImageRange]()

    let mainImageName = Bundle.main.executableURL?.lastPathComponent ?? ""
    let appRootPath = Self.appRootPath

    for index in 0 ..< _dyld_image_count() {
      guard
        let rawName = _dyld_get_image_name(index),
        let header = _dyld_get_image_header(index)
      else {
        continue
      }

      let path = String(cString: rawName)
      let name = (path as NSString).lastPathComponent
      let slide = _dyld_get_image_vmaddr_slide(index)
      let start = UInt64(UInt(bitPattern: header))

      guard let uuid = Self.uuid(from: header) else { continue }

      let isMain = name == mainImageName

      images.append(
        CrashReportPayload.BinaryImage(
          name: name,
          uuid: uuid,
          loadAddress: "0x" + String(start, radix: 16),
          slide: slide,
          arch: Self.arch(from: header),
          isMainExecutable: isMain,
          isAppImage: isMain || path.hasPrefix(appRootPath)
        )
      )

      ranges.append(ImageRange(uuid: uuid, name: name, start: start, size: Self.textSegmentSize(from: header)))
    }

    return BinaryImageTable(images: images, ranges: ranges.sorted { $0.start < $1.start })
  }

  /// Which image an address falls inside, if any.
  func image(containing address: UInt64) -> ImageRange? {
    var match: ImageRange?

    for range in ranges where range.start <= address {
      if let size = range.size, address >= range.start + size { continue }
      // Ranges are sorted, so the last one that starts at or below the address wins.
      match = range
    }

    return match
  }

  /// The bundle whose binaries count as ours.
  ///
  /// For an extension that's the app it ships in, not the `.appex`: Bloom's frameworks live in
  /// `Bloom.app/Frameworks`, outside the extension's own bundle, and a crash in BloomFoundation is
  /// as much ours from a Screen Time extension as from the app.
  static var appRootPath: String {
    var url = Bundle.main.bundleURL.resolvingSymlinksInPath()
    if url.pathExtension == "appex" {
      // Bloom.app/PlugIns/Extension.appex -> Bloom.app
      url = url.deletingLastPathComponent().deletingLastPathComponent()
    }
    return url.path
  }
}

// MARK: - Mach headers

private extension BinaryImageTable {

  /// The `LC_UUID` load command, formatted the way `dwarfdump --uuid` prints it.
  static func uuid(from header: UnsafePointer<mach_header>) -> String? {
    var result: String?
    forEachLoadCommand(in: header) { cursor, command in
      guard command.cmd == UInt32(LC_UUID) else { return false }

      let bytes = cursor.assumingMemoryBound(to: uuid_command.self).pointee.uuid
      result = withUnsafeBytes(of: bytes) { buffer in
        buffer.map { String(format: "%02X", $0) }.joined()
      }
      return true
    }
    return result
  }

  /// How far the image's text segment runs, so an address can be attributed to it.
  static func textSegmentSize(from header: UnsafePointer<mach_header>) -> UInt64? {
    var result: UInt64?
    forEachLoadCommand(in: header) { cursor, command in
      let segname: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)
      let vmsize: UInt64

      switch command.cmd {
      case UInt32(LC_SEGMENT_64):
        let segment = cursor.assumingMemoryBound(to: segment_command_64.self).pointee
        segname = segment.segname
        vmsize = segment.vmsize
      case UInt32(LC_SEGMENT):
        let segment = cursor.assumingMemoryBound(to: segment_command.self).pointee
        segname = segment.segname
        vmsize = UInt64(segment.vmsize)
      default:
        return false
      }

      let name = withUnsafeBytes(of: segname) { bytes in
        String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
      }
      guard name == SEG_TEXT else { return false }

      result = vmsize
      return true
    }
    return result
  }

  /// Walks the load commands until `body` returns true.
  ///
  /// Handles 32-bit headers as well as 64-bit: older watches run arm64_32, which is a 32-bit
  /// Mach-O with a smaller header and `LC_SEGMENT` rather than `LC_SEGMENT_64`.
  static func forEachLoadCommand(
    in header: UnsafePointer<mach_header>,
    _ body: (UnsafeRawPointer, load_command) -> Bool
  ) {
    let is64Bit = header.pointee.magic == MH_MAGIC_64
    let headerSize = is64Bit ? MemoryLayout<mach_header_64>.size : MemoryLayout<mach_header>.size
    var cursor = UnsafeRawPointer(header).advanced(by: headerSize)

    for _ in 0 ..< header.pointee.ncmds {
      let command = cursor.assumingMemoryBound(to: load_command.self).pointee
      if body(cursor, command) { return }
      cursor = cursor.advanced(by: Int(command.cmdsize))
    }
  }

  static func arch(from header: UnsafePointer<mach_header>) -> String {
    switch header.pointee.cputype {
    case CPU_TYPE_ARM64:
      return header.pointee.cpusubtype == CPU_SUBTYPE_ARM64E ? "arm64e" : "arm64"
    case CPU_TYPE_ARM64_32:
      return "arm64_32"
    case CPU_TYPE_X86_64:
      return "x86_64"
    default:
      return "unknown"
    }
  }
}
