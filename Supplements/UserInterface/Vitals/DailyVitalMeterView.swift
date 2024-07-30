//
//  DailyVitalMeterView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-23.
//

import SwiftUI

private extension CGFloat {
    static let lineWidth: CGFloat = 25

    static let arcStart: CGFloat = 0.55
    static let arcEnd: CGFloat = 0.95
    static let selectedZoneArcLength: CGFloat = 0.2
    static let arcSpacing: CGFloat = 0.035
    static let dotDimension: CGFloat = 20
}

struct DailyVitalMeterView: View {
    let meterValue: CGFloat

    var body: some View {
        HStack {
            Spacer()

            ZStack {
                Circle()
                    .trim(from: zone1ArcStart, to: zone1ArcEnd)
                    .stroke(.pink, style: StrokeStyle(lineWidth: .lineWidth, lineCap: .round))
                Circle()
                    .trim(from: zone2ArcStart, to: zone2ArcEnd)
                    .stroke(.yellow, style: StrokeStyle(lineWidth: .lineWidth, lineCap: .round))
                Circle()
                    .trim(from: zone3ArcStart, to: zone3ArcEnd)
                    .stroke(.green, style: StrokeStyle(lineWidth: .lineWidth, lineCap: .round))
                Circle()
                    .trim(from: zone4ArcStart, to: zone4ArcEnd)
                    .stroke(.coreSleep, style: StrokeStyle(lineWidth: .lineWidth, lineCap: .round))

                Circle()
                    .trim(from: dotArcStart, to: dotArcStart + 0.000001)
                    .stroke(.white, style: StrokeStyle(lineWidth: .dotDimension, lineCap: .round))

                VStack {
                    Text(stateText)
                        .font(.system(size: 40))
                        .bold()
                        .fontDesign(.rounded)
                    Text("Strain Meter")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 100)
            }
            .frame(width: 280)
            .padding(.bottom, -130)

            Spacer()
        }
        .padding()
        .animation(.bouncy(duration: 1.5), value: meterValue)
    }
}

private extension DailyVitalMeterView {

    var stateText: String {
        if meterValue < 0 {
            ""
        } else if cappedMeterValue <= 0.25 {
            "Concern"
        } else if cappedMeterValue > 0.25 && cappedMeterValue <= 0.5 {
            "Caution"
        } else if cappedMeterValue > 0.5 && cappedMeterValue <= 0.75 {
            "Good"
        } else {
            "Amazing"
        }
    }
}

private extension DailyVitalMeterView {

    var cappedMeterValue: CGFloat {
        min(max(meterValue, 0), 1)
    }

    var unselectedArcLength: CGFloat {
        (.arcEnd - .arcStart - (3.0 * .arcSpacing) - .selectedZoneArcLength) / 3.0
    }

    var zone1ArcStart: CGFloat {
        .arcStart
    }

    var zone1ArcEnd: CGFloat {
        if cappedMeterValue <= 0.25 {
            return zone1ArcStart + .selectedZoneArcLength
        }
        return zone1ArcStart + unselectedArcLength
    }

    var zone2ArcStart: CGFloat {
        zone1ArcEnd + .arcSpacing
    }

    var zone2ArcEnd: CGFloat {
        if cappedMeterValue > 0.25 && cappedMeterValue <= 0.5 {
            return zone2ArcStart + .selectedZoneArcLength
        }
        return zone2ArcStart + unselectedArcLength
    }

    var zone3ArcStart: CGFloat {
        zone2ArcEnd + .arcSpacing
    }

    var zone3ArcEnd: CGFloat {
        if cappedMeterValue > 0.5 && cappedMeterValue <= 0.75 {
            return zone3ArcStart + .selectedZoneArcLength
        }
        return zone3ArcStart + unselectedArcLength
    }

    var zone4ArcStart: CGFloat {
        zone3ArcEnd + .arcSpacing
    }

    var zone4ArcEnd: CGFloat {
        if cappedMeterValue > 0.75 {
            return zone4ArcStart + .selectedZoneArcLength
        }
        return zone4ArcStart + unselectedArcLength
    }

    var dotArcStart: CGFloat {
        var arc = CGFloat.arcStart

        if cappedMeterValue <= 0.25 {
            arc += (CGFloat.selectedZoneArcLength * (cappedMeterValue / 0.25))
        } else if cappedMeterValue > 0.25 && cappedMeterValue <= 0.5 {
            arc += unselectedArcLength + .arcSpacing
            arc += (CGFloat.selectedZoneArcLength * ((cappedMeterValue - 0.25) / 0.25))
        } else if cappedMeterValue > 0.5 && cappedMeterValue <= 0.75 {
            arc += (unselectedArcLength + .arcSpacing) * 2
            arc += (CGFloat.selectedZoneArcLength * ((cappedMeterValue - 0.5) / 0.25))
        } else if cappedMeterValue > 0.75 {
            arc += (unselectedArcLength + .arcSpacing) * 3
            arc += (CGFloat.selectedZoneArcLength * ((cappedMeterValue - 0.75) / 0.25))
        }

        return arc
    }
}

#Preview {
    struct PreviewView: View {
        @State var progress: CGFloat = 0

        var body: some View {
            List {
                DailyVitalMeterView(meterValue: progress)
            }
            .onAppear {
                Delay(1000) {
                    progress = 0.69
                }
            }
        }
    }
    return PreviewView()
}
