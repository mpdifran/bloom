//
//  SignalHandler.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-09-29.
//

import Foundation
import Darwin

/// Catches the signals a crash arrives as, and writes down where it happened.
///
/// Everything here runs inside a process that is already broken, so the rules are strict and
/// worth stating rather than rediscovering:
///
/// - **No allocation.** `malloc` takes a lock. A `SIGSEGV` raised while the heap is corrupt, or
///   while another thread holds that lock, deadlocks or faults again - losing exactly the report
///   you most wanted. Every buffer here is allocated at install.
/// - **No Swift `String`, no `Foundation`, no `Logger`.** All of them allocate.
/// - **`write(2)`, `_exit`, `backtrace`, `sigaction` and `raise` only** - the async-signal-safe
///   subset this needs.
/// - **Re-raise with the default handler in place.** Swallowing the signal would deny the OS its
///   own crash report, and MetricKit with it.
///
/// The file it writes is parsed on the next launch by `SignalReportParser`, where Foundation is
/// available and nothing is on fire.
enum SignalHandler {

  /// The signals a crash actually arrives as.
  ///
  /// `SIGTRAP` matters more than it looks: Swift's `fatalError`, a force-unwrapped nil, an
  /// array index out of range and an integer overflow all compile to `brk`, which lands here.
  /// Leaving it out - as the Mac version this is ported from does - misses the most common way
  /// a Swift app dies.
  static let handled: [Int32] = [SIGABRT, SIGSEGV, SIGBUS, SIGILL, SIGFPE, SIGTRAP]

  fileprivate static let maximumFrames = 128
}

// MARK: - Installing

extension SignalHandler {

  /// Arms the handlers. Call once, early, and never off the main thread.
  static func install(reportPath: String) {
    guard !isDebuggerAttached() else {
      // LLDB takes the signal first, so the handler either never runs or runs after the
      // debugger has already changed the situation. Better to do nothing visible than to
      // half-work and look broken.
      return
    }

    guard openReportFile(at: reportPath) else { return }

    allocateBuffers()
    installAlternateStack()

    for signalNumber in handled {
      var action = sigaction()
      action.__sigaction_u.__sa_handler = handleSignal
      sigemptyset(&action.sa_mask)
      // SA_ONSTACK is what makes a stack-overflow crash reportable: without it the handler
      // runs on the stack that just overflowed and faults immediately. watchOS has no
      // `sigaltstack`, so a stack overflow on the watch goes unreported by this path.
      #if os(watchOS)
      action.sa_flags = 0
      #else
      action.sa_flags = SA_ONSTACK
      #endif

      sigaction(signalNumber, &action, nil)
    }
  }
}

// MARK: - The handler

/// Set while the handler runs. A second signal - one raised *by* the handler - exits rather than
/// looping through a half-written report.
private nonisolated(unsafe) var isHandling: sig_atomic_t = 0

private nonisolated(unsafe) var reportDescriptor: Int32 = -1
private nonisolated(unsafe) var frameBuffer: UnsafeMutablePointer<UnsafeMutableRawPointer?>?
private nonisolated(unsafe) var hexBuffer: UnsafeMutablePointer<UInt8>?
private nonisolated(unsafe) var alternateStack: UnsafeMutableRawPointer?

/// The whole of what runs inside the crash.
private func handleSignal(_ signalNumber: Int32) {
  guard isHandling == 0 else {
    _exit(1)
  }
  isHandling = 1

  guard reportDescriptor >= 0, let frameBuffer, let hexBuffer else {
    restoreDefault(for: signalNumber)
    raise(signalNumber)
    return
  }

  writeLiteral("SIGNAL ")
  writeSignalName(signalNumber)
  writeLiteral("\n")

  // time(nil) is async-signal-safe; Date() is not.
  writeLiteral("TIME ")
  writeNumber(UInt64(time(nil)), buffer: hexBuffer, radix: 10)
  writeLiteral("\n")

  let frameCount = backtrace(frameBuffer, Int32(SignalHandler.maximumFrames))
  for index in 0 ..< Int(frameCount) {
    guard let frame = frameBuffer[index] else { continue }

    writeLiteral("FRAME 0x")
    writeNumber(UInt64(UInt(bitPattern: frame)), buffer: hexBuffer, radix: 16)
    writeLiteral("\n")
  }

  writeLiteral("END\n")
  fsync(reportDescriptor)

  // Hand the signal back to the system so it writes its own report too - which is what
  // MetricKit later delivers.
  restoreDefault(for: signalNumber)
  raise(signalNumber)
}

private func restoreDefault(for signalNumber: Int32) {
  var action = sigaction()
  action.__sigaction_u.__sa_handler = SIG_DFL
  sigemptyset(&action.sa_mask)
  action.sa_flags = 0
  sigaction(signalNumber, &action, nil)
}

// MARK: - Writing, without allocating

private func writeLiteral(_ text: StaticString) {
  text.withUTF8Buffer { buffer in
    guard let base = buffer.baseAddress else { return }
    _ = write(reportDescriptor, base, buffer.count)
  }
}

private func writeSignalName(_ signalNumber: Int32) {
  switch signalNumber {
  case SIGABRT: writeLiteral("SIGABRT")
  case SIGSEGV: writeLiteral("SIGSEGV")
  case SIGBUS: writeLiteral("SIGBUS")
  case SIGILL: writeLiteral("SIGILL")
  case SIGFPE: writeLiteral("SIGFPE")
  case SIGTRAP: writeLiteral("SIGTRAP")
  default: writeLiteral("UNKNOWN")
  }
}

/// Formats into the preallocated buffer, back to front, and writes it. No `String`, no `malloc`.
private func writeNumber(_ value: UInt64, buffer: UnsafeMutablePointer<UInt8>, radix: UInt64) {
  let digits: StaticString = "0123456789abcdef"

  var value = value
  var length = 0

  repeat {
    let digit = Int(value % radix)
    digits.withUTF8Buffer { table in
      buffer[length] = table[digit]
    }
    length += 1
    value /= radix
  } while value > 0 && length < 32

  // Reverse in place, then write once.
  var start = 0
  var end = length - 1
  while start < end {
    let temporary = buffer[start]
    buffer[start] = buffer[end]
    buffer[end] = temporary
    start += 1
    end -= 1
  }

  _ = write(reportDescriptor, buffer, length)
}

// MARK: - Setup

private extension SignalHandler {

  static func openReportFile(at path: String) -> Bool {
    // Opened now, while opening files is still safe. The handler only ever writes to it.
    let descriptor = path.withCString { cPath in
      open(cPath, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
    }

    guard descriptor >= 0 else { return false }

    reportDescriptor = descriptor
    return true
  }

  static func allocateBuffers() {
    if frameBuffer == nil {
      frameBuffer = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: maximumFrames)
      frameBuffer?.initialize(repeating: nil, count: maximumFrames)
    }

    if hexBuffer == nil {
      hexBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
      hexBuffer?.initialize(repeating: 0, count: 32)
    }
  }

  /// A separate stack for the handler to run on, so a stack overflow can still be reported.
  static func installAlternateStack() {
    #if !os(watchOS)
    guard alternateStack == nil else { return }

    let size = max(Int(SIGSTKSZ), 64 * 1024)
    let memory = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 16)
    alternateStack = memory

    var stack = stack_t()
    stack.ss_sp = memory
    stack.ss_size = size
    stack.ss_flags = 0

    sigaltstack(&stack, nil)
    #endif
  }

  /// Whether a debugger is attached, via the documented `P_TRACED` check.
  static func isDebuggerAttached() -> Bool {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

    let result = sysctl(&name, UInt32(name.count), &info, &size, nil, 0)
    guard result == 0 else { return false }

    return (info.kp_proc.p_flag & P_TRACED) != 0
  }
}
