//
//  SalesDebugView.swift
//  Bloom
//

import AppUI
import BloomModel
import SwiftUI
import SFSafeSymbols

struct SalesDebugView: View {
  @State private var sales: [SaleDetails] = []
  @State private var eligibilityStates: [String: SaleEligibilityState] = [:]
  @State private var lastFetchedDate: Date?
  @State private var isLoading = true

  @AppStorage(String.SaleOverrideKey.overriddenSaleId, store: .group)
  private var overriddenSaleId: String?

  @AppStorage(String.SaleOverrideKey.alwaysShowOnForeground, store: .group)
  private var alwaysShowOnForeground = false

  var body: some View {
    VStack {
      SectionTitleView("Sales")
        .padding(.horizontal)

      if isLoading {
        loadingView
      } else if sales.isEmpty {
        noContentView
      } else {
        saleContentView
      }

      if overriddenSaleId != nil {
        alwaysShowToggle
        clearLastViewedDateButton
      }

      refreshButton

      if let lastFetched = lastFetchedDate {
        lastFetchedLabel(lastFetched: lastFetched)
      }
    }
    .animation(.default, value: overriddenSaleId)
    .animation(.default, value: sales)
    .animation(.default, value: isLoading)
    .task {
      await loadSales()
    }
  }
}

private extension SalesDebugView {

  var loadingView: some View {
    ProgressView()
      .horizontallyCentered()
      .frame(height: 60)
      .cardContainer()
  }

  var noContentView: some View {
    Text("No cached sales")
      .horizontallyCentered()
      .foregroundStyle(.secondary)
      .frame(height: 60)
      .cardContainer()
  }

  var saleContentView: some View {
    ForEach(sales) { sale in
      if let state = eligibilityStates[sale.id] {
        SaleDebugCell(
          sale: sale,
          eligibilityState: state,
          isOverridden: overriddenSaleId == sale.id,
          onOverrideChanged: { isOverridden in
            if isOverridden {
              overriddenSaleId = sale.id
            } else {
              overriddenSaleId = nil
            }
          }
        )
        .cardContainer()
      }
    }
  }

  var refreshButton: some View {
    AsyncButton {
      await SalesManager.shared.forceRefreshSales()
      await loadSales()
    } label: {
      Text("Refresh Sales")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }

  var alwaysShowToggle: some View {
    Toggle("Always Show on Foreground", isOn: $alwaysShowOnForeground)
      .padding(.horizontal)
      .cardContainer()
  }

  var clearLastViewedDateButton: some View {
    Button(role: .destructive) {
      Task {
        if let saleId = overriddenSaleId {
          await SalesManager.shared.clearLastShownDate(for: saleId)
          await loadSales()
        }
      }
    } label: {
      Text("Clear Last Viewed Date")
        .horizontallyCentered()
    }
    .buttonStyle(.primary)
  }

  func lastFetchedLabel(lastFetched: Date) -> some View {
    Text("Last fetched: \(lastFetched.formatted(date: .abbreviated, time: .shortened))")
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(.horizontal)
  }
}

private extension SalesDebugView {

  func loadSales() async {
    isLoading = true
    sales = await SalesManager.shared.getCachedSales()
    lastFetchedDate = await SalesManager.shared.getLastFetchedDate()

    for sale in sales {
      let state = await SalesManager.shared.getEligibilityState(for: sale)
      eligibilityStates[sale.id] = state
    }

    isLoading = false
  }
}

#Preview {
  PreviewEnvironment {
    ScrollView {
      SalesDebugView()
        .padding()
    }
  }
}
