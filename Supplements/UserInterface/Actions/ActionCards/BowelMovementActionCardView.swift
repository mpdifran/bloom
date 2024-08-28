//
//  BowelMovementActionCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-26.
//

import SwiftUI
import SwiftData

struct BowelMovementActionCardView: View {
    @State private var date = Date.now
    @State private var selectedStoolType: Int = 0
    @State private var duration: BowelMovement.Duration = .between5And10Min

    var body: some View {
        ActionCardView(title: "New Bowel Movement") { modelContext in
            let model = BowelMovement(
                date: date,
                bristolStoolType: selectedStoolType,
                duration: duration
            )
            modelContext.insert(model)
            return true
        } content: { (_, _) in
            ScrollView {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                        HStack {
                            VStack {
                                Spacer(minLength: 0)
                                Text("Unknown")
                                    .font(.subheadline)
                                    .bold()
                                Spacer(minLength: 0)
                                Image(systemName: "questionmark.app.fill")
                                    .font(.largeTitle)

                                Spacer(minLength: 0)
                            }
                            .frame(width: 130)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(.background.secondary)
                            }
                            .overlay {
                                if selectedStoolType == 0 {
                                    RoundedRectangle(cornerRadius: 13)
                                        .stroke(.tint, lineWidth: 3)
                                }
                            }
                            .id(0)
                            .onTapGesture {
                                selectedStoolType = 0
                            }

                            ForEach(1...7, id: \.self) { stoolType in
                                VStack {
                                    Text("Type \(stoolType)")
                                        .font(.subheadline)
                                        .bold()
                                    Image("Type \(stoolType)")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 13))

                                    Spacer()

                                    Text(description(for: stoolType))
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(width: 130)
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 13)
                                        .fill(.background.secondary)
                                }
                                .overlay {
                                    if selectedStoolType == stoolType {
                                        RoundedRectangle(cornerRadius: 13)
                                            .stroke(.tint, lineWidth: 3)
                                    }
                                }
                                .onTapGesture {
                                    selectedStoolType = stoolType
                                }
                            }
                        }
                        .padding()
                    }
                    .scrollIndicators(.never)
                    .onChange(of: selectedStoolType) { (_, newValue) in
                        withAnimation {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: selectedStoolType)

                LabeledContent("Duration") {
                    Picker("", selection: $duration) {
                        ForEach(BowelMovement.Duration.allCases) { duration in
                            Text(duration.name)
                                .tag(duration)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .cardContainer(fill: .background.secondary, includePadding: false)
                .padding(.horizontal)

                LabeledContent("Date") {
                    DatePicker("", selection: $date)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .cardContainer(fill: .background.secondary, includePadding: false)
                .padding(.horizontal)
            }
        }
        .tint(.brown)
    }
}

private extension BowelMovementActionCardView {

    func description(for type: Int) -> String {
        switch type {
        case 1: "Separate hard lumps, hard to pass"
        case 2: "Sausage shape but lumpy"
        case 3: "Like a sausage but with cracks"
        case 4: "Like a sausage, smooth and long"
        case 5: "Soft blobs with clear cut edges"
        case 6: "Mushy consistency with ragged edges"
        case 7: "Liquid consistency with no solid pieces"
        default: ""
        }
    }
}

#Preview {
    struct PreviewView: View {

        @State private var showSheet = true

        var body: some View {
            Button {
                showSheet.toggle()
            } label: {
                Text("Show Sheet")
            }
            .sheet(isPresented: $showSheet) {
                BowelMovementActionCardView()
            }
        }
    }
    return PreviewView()
}
