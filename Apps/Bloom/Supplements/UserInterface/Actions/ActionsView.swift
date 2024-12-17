//
//  ActionsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI

struct ActionsView: View {

  @State private var showAllDataView = false
  @State private var presentedCardSheet: AnyView?

  @State private var viewModel = ViewModel()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          NutritionQuickActionCell(
            title: "Search Food",
            subtitle: "Search and add food you've eaten.",
            systemImage: "magnifyingglass"
          )
          .onTapGesture {
            presentedCardSheet = FoodLoggingActionCardView().asAny
          }

          HStack {
            NutritionQuickActionCell(
              title: "AI Scan",
              subtitle: "Log food instantly via AI.",
              systemImage: "sparkles"
            )
            .onTapGesture {
              presentedCardSheet = AIFoodScannerView().asAny
            }
            NutritionQuickActionCell(
              title: "Scan Barcode",
              subtitle: "Scan a barcode to quickly log food.",
              systemImage: "barcode.viewfinder"
            )
            .onTapGesture {
              presentedCardSheet = FoodBarcodeScannerView(onBarcodeScan: { (barcode) in
                Task {
                  await delayShowFoodSearch(for: barcode)
                }
              }).asAny
            }
          }

          HStack {
            ActionStatusCell(
              title: "Log Weight",
              systemImage: "gauge.with.dots.needle.bottom.50percent.badge.plus",
              latestValue: viewModel.weightDetails?.displayString,
              latestTimestamp: viewModel.weightDetails?.timestampString
            )
            .tint(.mutedIndigo)
            .onTapGesture {
              presentedCardSheet = BodyWeightActionCardView().asAny
            }

            ActionStatusCell(
              title: "Log Blood Pressure",
              systemImage: "gauge.open.with.lines.needle.67percent.and.arrowtriangle",
              latestValue: viewModel.bloodPressureDetails?.displayString,
              latestTimestamp: viewModel.bloodPressureDetails?.timestampString
            )
            .tint(.mutedPink)
            .onTapGesture {
              presentedCardSheet = BloodPressureActionCardView().asAny
            }
          }

          HStack {
            ActionStatusCell(
              title: "Log Water",
              systemImage: "waterbottle.fill",
              latestValue: viewModel.waterDetails?.displayString,
              latestTimestamp: viewModel.waterDetails?.timestampString
            )
            .tint(.mutedBlue)
            .onTapGesture {
              presentedCardSheet = WaterActionCardView().asAny
            }

            ActionStatusCell(
              title: "Log Bowel Movement",
              systemImage: "toilet.fill",
              latestValue: viewModel.bowelMovementDetails?.displayString,
              latestTimestamp: viewModel.bowelMovementDetails?.timestampString
            )
            .tint(.brown)
            .onTapGesture {
              presentedCardSheet = BowelMovementActionCardView().asAny
            }
          }
        }
        .padding()
        .onAppear {
          viewModel.observeData()
        }
      }
      .navigationTitle("Log")
      .tabBar()
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button(action: {
            showAllDataView = true
          }, label: {
            Text("All Data")
          })
        }
      }
      .navigationDestination(isPresented: $showAllDataView) {
        AllActionDataListView()
      }
    }
    .sheet($presentedCardSheet)
  }
}

private extension ActionsView {

  func delayShowFoodSearch(for barcode: String) async {
    await Delay(500)

    presentedCardSheet = FoodLoggingActionCardView(initialBarcodeToSearch: barcode).asAny
  }
}

#Preview {
  TabView {
    ActionsView()
  }
}
