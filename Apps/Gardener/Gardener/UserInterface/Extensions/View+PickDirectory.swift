//
//  View+PickDirectory.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-04.
//

import SwiftUI

extension View {

  func pickDirectory(showPicker: Binding<Bool>, handler: @escaping (URL?) -> Void) -> some View {
    onChange(of: showPicker.wrappedValue) { _, newValue in
      guard newValue else {
        showPicker.wrappedValue = false
        return
      }

      let folderChooserPoint = CGPoint(x: 0, y: 0)
      let folderChooserSize = CGSize(width: 500, height: 600)
      let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
      let folderPicker = NSOpenPanel(
        contentRect: folderChooserRectangle,
        styleMask: .utilityWindow,
        backing: .buffered,
        defer: true
      )

      folderPicker.canChooseDirectories = true
      folderPicker.canChooseFiles = false
      folderPicker.allowsMultipleSelection = false
      folderPicker.canDownloadUbiquitousContents = true
      folderPicker.canResolveUbiquitousConflicts = true

      folderPicker.begin { response in
        if response == .OK {
          handler(folderPicker.url)
          showPicker.wrappedValue = false
        }
      }
    }
  }

  func pickFile(showPicker: Binding<Bool>, handler: @escaping (URL?) -> Void) -> some View {
    onChange(of: showPicker.wrappedValue) { _, newValue in
      guard newValue else {
        showPicker.wrappedValue = false
        return
      }

      let folderChooserPoint = CGPoint(x: 0, y: 0)
      let folderChooserSize = CGSize(width: 500, height: 600)
      let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
      let filePicker = NSOpenPanel(
          contentRect: folderChooserRectangle,
          styleMask: .utilityWindow,
          backing: .buffered,
          defer: true
      )

//      filePicker.directoryURL = localizedDirectory
      filePicker.canChooseDirectories = false
      filePicker.canChooseFiles = true
      filePicker.allowsMultipleSelection = false
      filePicker.canDownloadUbiquitousContents = true
      filePicker.canResolveUbiquitousConflicts = true

      filePicker.begin { response in
          if response == .OK {
              handler(filePicker.url)
          }
      }
    }
  }
}
