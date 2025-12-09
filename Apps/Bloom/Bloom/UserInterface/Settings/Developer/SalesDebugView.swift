//
//  SalesDebugView.swift
//  Bloom
//

import AppUI
import BloomModel
import SwiftUI

struct SalesDebugView: View {
  @State private var sales: [SaleDetails] = []
  @State private var eligibilityStates: [String: SaleEligibilityState] = [:]
  @State private var lastFetchedDate: Date?
  @State private var isLoading = true
  @State private var isRefreshing = false
  @AppStorage(String.SaleOverrideKey.overriddenSaleId, store: .group)
  private var overriddenSaleId: String?

  var body: some View {
    VStack {
      SectionTitleView("Sales")
        .padding(.horizontal)

      SettingsSectionContainer {
        if isLoading {
          ProgressView()
            .frame(height: 60)
        } else if sales.isEmpty {
          Text("No cached sales")
            .horizontallyCentered()
            .foregroundStyle(.secondary)
            .frame(height: 60)
        } else {
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

              if sale.id != sales.last?.id {
                Divider()
              }
            }
          }
        }

        Divider()

        AsyncButton {
          isRefreshing = true
          await SalesManager.shared.forceRefreshSales()
          await loadSales()
          isRefreshing = false
        } label: {
          LabeledContent("Refresh Sales") {
            if isRefreshing {
              ProgressView()
            } else {
              Image(systemName: "arrow.clockwise")
            }
          }
          .bold()
          .fontDesign(.rounded)
          .foregroundStyle(.tint)
          .frame(height: 60)
        }
        .disabled(isRefreshing)

        if overriddenSaleId != nil {
          Divider()

          Button(role: .destructive) {
            overriddenSaleId = nil
          } label: {
            Text("Clear Override")
              .bold()
              .fontDesign(.rounded)
              .horizontallyCentered()
              .frame(height: 60)
          }
        }
      }

      if let lastFetched = lastFetchedDate {
        Text("Last fetched: \(lastFetched.formatted(date: .abbreviated, time: .shortened))")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.horizontal)
      }
    }
    .task {
      await loadSales()
    }
  }

  private func loadSales() async {
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
