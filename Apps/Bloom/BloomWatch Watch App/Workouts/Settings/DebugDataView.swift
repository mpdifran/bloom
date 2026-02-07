//
//  DebugDataView.swift
//  BloomWatch Watch App
//
//  Created by Mark DiFranco on 2026-02-02.
//

import SwiftUI
import SFSafeSymbols

struct DebugDataView: View {
  @State private var presentedNavigationDestination: AnyView?

  var body: some View {
    List {
      mockBioAgeCell
      syncedDataCell
    }
    .listStyle(.carousel)
    .navigationTitle("Debug")
    .navigationDestination($presentedNavigationDestination)
  }
}

// MARK: - Cells

private extension DebugDataView {

  var mockBioAgeCell: some View {
    HStack(spacing: 10) {
      Circle()
        .fill(.green.gradient)
        .overlay {
          Image(systemSymbol: .clockBadge)
            .font(.system(size: 16))
            .foregroundStyle(.black)
        }
        .frame(square: 35)

      Text("Mock Bio Age")
        .font(.caption)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.white)

      Spacer()
    }
    .padding(.vertical, 10)
    .selectable()
    .onTapGesture {
      presentedNavigationDestination = DebugMockBioAgeView().asAny
    }
  }

  var syncedDataCell: some View {
    HStack(spacing: 10) {
      Circle()
        .fill(.blue.gradient)
        .overlay {
          Image(systemSymbol: .arrowTrianglehead2ClockwiseRotate90)
            .font(.system(size: 16))
            .foregroundStyle(.black)
        }
        .frame(square: 35)

      Text("Synced Data")
        .font(.caption)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(.white)

      Spacer()
    }
    .padding(.vertical, 10)
    .selectable()
    .onTapGesture {
      presentedNavigationDestination = DebugSyncedDataView().asAny
    }
  }
}

#Preview {
  PreviewEnvironment {
    DebugDataView()
  }
}
