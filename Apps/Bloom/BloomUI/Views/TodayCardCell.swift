//
//  TodayCardCell.swift
//  BloomUI
//
//  Created by Mark DiFranco on 2025-08-28.
//

import SwiftUI
import SFSafeSymbols
import AppUI

public struct TodayCardCell<Content: View>: View {
  let symbol: SFSymbol
  let title: String
  let content: String
  let color: Color
  let contentBuilder: (() -> Content)?

  public init(
    symbol: SFSymbol,
    title: String,
    content: String,
    color: Color,
    contentBuilder: @escaping () -> Content
  ) {
    self.symbol = symbol
    self.title = title
    self.content = content
    self.color = color
    self.contentBuilder = contentBuilder
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      headerView

      Text(content)
        .font(.body)
        .fontDesign(.rounded)

      if let contentBuilder {
        contentBuilder()
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .foregroundStyle(.white)
    .horizontallyCentered()
    .cardContainer(fill: color.gradient)
  }
}

public extension TodayCardCell where Content == EmptyView {

  init(
    symbol: SFSymbol,
    title: String,
    content: String,
    color: Color
  ) {
    self.symbol = symbol
    self.title = title
    self.content = content
    self.color = color
    self.contentBuilder = nil
  }
}

private extension TodayCardCell {

  @ViewBuilder
  var headerView: some View {
    HStack {
      Image(systemSymbol: symbol)
        .font(.title3)
        .foregroundStyle(color)
        .frame(square: 30)
        .padding(6)
        .background {
          RoundedRectangle(cornerRadius: 13)
            .fill(.white)
        }

      Text(title)
        .font(.title3)
        .fontDesign(.rounded)
        .bold()

      Spacer()
    }
  }
}
