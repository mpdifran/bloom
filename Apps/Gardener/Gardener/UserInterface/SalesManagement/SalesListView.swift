//
//  SalesListView.swift
//  Gardener
//
//  Created by Claude on 2025-12-02.
//

import AdminBloomModel
import AppUI
import SwiftUI

struct SalesListView: View {
  @ObservedObject private var store = SalesStore.shared
  @State private var selectedSale: AdminSaleRecord?

  var body: some View {
    Group {
      if store.isLoading && store.sales.isEmpty {
        ProgressView()
      } else if store.sales.isEmpty {
        ContentUnavailableView(
          "No Sales",
          systemImage: "tag",
          description: Text("Create your first sale to get started")
        )
      } else {
        List(store.sales, id: \.id, selection: $selectedSale) { sale in
          NavigationLink {
            let viewModel = SaleDetailViewModel(sale: sale, store: store)
            SaleDetailView(viewModel: viewModel)
          } label: {
            SaleRow(sale: sale)
              .tag(sale)
          }
        }
      }
    }
    .navigationTitle("Sales Management")
    .toolbar {
        ToolbarItem(placement: .primaryAction) {
          refreshButton
        }
        ToolbarItem(placement: .primaryAction) {
          addButton
        }
      }
      .task {
        await store.loadSales()
      }
      .alert(error: $store.error)
  }

  private var refreshButton: some View {
    Button {
      Task {
        await store.loadSales()
      }
    } label: {
      Label("Refresh", systemImage: "arrow.clockwise")
    }
    .disabled(store.isLoading)
  }

  private var addButton: some View {
    AsyncButton {
      Task {
        let newSale = AdminSaleRecord(
          id: nil,
          title: "New Sale",
          bodyText: "This is a new sale.",
          imageURL: nil,
          saleProductId: "",
          compareProductId: nil,
          targetAudiences: [.freeUsers],
          startDate: Date(),
          endDate: Date().addingTimeInterval(86400 * 7), // 7 days from now
          displayFrequencyDays: 7,
          isActive: false,
          telemetryEventName: "",
          purchaseButtonTitle: "Upgrade",
          purchaseButtonGradientColors: nil,
          purchaseButtonFooterText: "Share with up to 5 family members",
          discountBadgeBackgroundColor: nil,
          discountBadgeForegroundColor: nil,
          createdAt: nil,
          updatedAt: nil
        )

        // Create sale in backend immediately
        if let createdSale = try await store.create(sale: newSale, image: nil) {
          // Sale is automatically added to store.sales by the create method
          // Select the newly created sale
          selectedSale = createdSale
        }
      }
    } label: {
      Label("Add Sale", systemImage: "plus")
    }
  }
}

private struct SaleRow: View {
  let sale: AdminSaleRecord

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(sale.title.isEmpty ? "Untitled Sale" : sale.title)
          .font(.headline)

        Spacer()

        statusIndicator
      }

      HStack(spacing: 4) {
        Image(systemName: "calendar")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text(dateRangeString)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 8)
  }

  private var statusIndicator: some View {
    HStack(spacing: 4) {
      Image(systemName: sale.isActive ? "checkmark.circle.fill" : "circle")
        .font(.caption)
        .foregroundStyle(sale.isActive ? .green : .secondary)

      Text(sale.isActive ? "Active" : "Inactive")
        .font(.caption)
        .foregroundStyle(sale.isActive ? .green : .secondary)
    }
  }

  private var dateRangeString: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none

    let startString = formatter.string(from: sale.startDate)
    let endString = formatter.string(from: sale.endDate)

    return "\(startString) - \(endString)"
  }
}

#Preview {
  NavigationSplitView {
    Text("Sidebar")
  } content: {
    SalesListView()
  } detail: {
    Text("Detail")
  }
}
