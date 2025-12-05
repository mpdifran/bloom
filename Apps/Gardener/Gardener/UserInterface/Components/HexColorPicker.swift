//
//  HexColorPicker.swift
//  Gardener
//
//  Created by Claude on 2025-12-05.
//

import SwiftUI

struct HexColorPicker: View {
  let title: String
  @Binding var hexString: String
  @State private var color: Color

  init(title: String, hexString: Binding<String>) {
    self.title = title
    self._hexString = hexString
    self._color = State(initialValue: Color(hex: hexString.wrappedValue) ?? .gray)
  }

  var body: some View {
    HStack {
      ColorPicker(title, selection: $color, supportsOpacity: false)
        .onChange(of: color) { _, newColor in
          hexString = newColor.toHex() ?? ""
        }
      TextField("Hex", text: $hexString)
        .textFieldStyle(.roundedBorder)
        .frame(width: 100)
        .onChange(of: hexString) { _, newHex in
          if let parsed = Color(hex: newHex) {
            color = parsed
          }
        }
    }
  }
}

#Preview {
  VStack {
    HexColorPicker(title: "Background", hexString: .constant("#FF5733"))
    HexColorPicker(title: "Foreground", hexString: .constant("#007AFF"))
  }
  .padding()
}
