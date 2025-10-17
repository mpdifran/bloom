//
//  HabitGridYear.swift
//  Bloom
//
//  Created by Assistant on 2025-06-28.
//

import SwiftUI
import AppUI
import BloomFoundation

private extension CGFloat {
    static let spacing: CGFloat = 4
    static let minCellWidth: CGFloat = 120
    static let labelHeight: CGFloat = 20
}

private extension Double {
    static let cellDelay: Double = 0.08
}

struct HabitGridYear: View {
    let model: HabitGridYearModel
    
    @State private var completionSensoryToggle = false
    
    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .bottom, spacing: .spacing) {
                ForEachEnumerated(model.years) { (columnIndex, year) in
                    if recommendedMaxColumnCount(for: proxy.size.width) > (model.years.count - columnIndex - 1) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(year.yearLabel)
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.secondary)
                                .frame(height: .labelHeight, alignment: .bottom)
                            
                            HabitGridYearCell(
                                id: "\(year.id)",
                                isComplete: year.isComplete,
                                isToday: year.isCurrentYear
                            )
                            .transition(.scale)
                            .animation(
                                .bouncy
                                    .delay(delay(column: columnIndex, width: proxy.size.width)),
                                value: year.isComplete
                            )
                        }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: completionSensoryToggle)
            .onChange(of: model) { _, _ in
                delayedSensoryFeedback(proxy: proxy)
            }
        }
        .frame(height: 80 + .labelHeight)
        .padding(.horizontal, .spacing)
    }
}

extension HabitGridYear {
    
    func delayedSensoryFeedback(proxy: GeometryProxy) {
        let maxColumns = recommendedMaxColumnCount(for: proxy.size.width)
        
        for columnIndex in 0 ..< model.years.count {
            guard maxColumns > (model.years.count - columnIndex - 1) else { continue }
            guard model.years[columnIndex].isComplete == true else { continue }
            
            let delay = delay(column: columnIndex, width: proxy.size.width)
            
            Task {
                await Delay(Int(delay * 1000))
                
                await MainActor.run {
                    completionSensoryToggle.toggle()
                }
            }
        }
    }
    
    func delay(column: Int, width: CGFloat) -> Double {
        let maxColumnCount = recommendedMaxColumnCount(for: width)
        let difference = model.years.count - maxColumnCount
        let shiftedColumn = column - difference
        
        guard shiftedColumn > 0 else { return 0 }
        
        return Double(shiftedColumn) * Double.cellDelay * 2
    }
    
    func recommendedMaxColumnCount(for width: CGFloat) -> Int {
        let remainingWidth = width - .minCellWidth
        return Int((remainingWidth / (.minCellWidth + .spacing)).rounded(.awayFromZero))
    }
}

#Preview {
    @Previewable @State var habitGridYearModel = HabitGridYearModel()
    
    VStack {
        HabitGridYear(model: habitGridYearModel)
            .padding(.spacing)
        
        HabitGridYear(model: HabitGridYearModel())
            .padding(.spacing)
        
        Spacer()
    }
    .tint(.mutedPink)
    .onAppear {
        withAnimation {
            habitGridYearModel = HabitGridYearModel(
                years: [
                    HabitGridYearModel.Year(id: 4, isComplete: false, yearLabel: "2025"),
                    HabitGridYearModel.Year(id: 3, isComplete: true, yearLabel: "2024"),
                    HabitGridYearModel.Year(id: 2, isComplete: true, yearLabel: "2023"),
                    HabitGridYearModel.Year(id: 1, isComplete: false, yearLabel: "2022"),
                    HabitGridYearModel.Year(id: 0, isComplete: false, isCurrentYear: true, yearLabel: "2021"),
                ]
            )
        }
    }
}
