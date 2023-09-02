//
//  SummaryView.swift
//  Wearable Sensor Watch App
//
//  Created by akhanafer on 2023-08-30.
//

import SwiftUI

struct SummaryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var durationFormatter:
    DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    var body: some View {
        ScrollView(.vertical){
            VStack(alignment: .leading){
                SummaryMetricView(title: "Total Time", value: durationFormatter.string(from:  30 * 60 + 15) ?? ""
                ).accentColor(.yellow)
                
                SummaryMetricView(title: "Total Distance", value: Measurement(value: 1625, unit: UnitLength.meters).formatted(.measurement(width: .abbreviated, usage: .road))).accentColor(.green)
                
                SummaryMetricView(
                    title: "Total Energy",
                    value: Measurement(
                        value: 96,
                        unit: UnitEnergy.kilocalories
                    ).formatted(
                        .measurement(
                            width: .abbreviated,
                            usage: .workout
                        )
                    )
                ).accentColor(.pink)

                SummaryMetricView(
                    title: "Avg. Heart Rate",
                    value: 143
                        .formatted(
                            .number.precision(.fractionLength(0))
                    ) + "bpm"
                ).accentColor(.red)
                
                Button("Done"){
                    dismiss()
                }
            }
            .scenePadding()
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SummaryMetricView: View {
    var title: String
    var value: String
    
    var body: some View {
        Text(title)
        Text(value)
            .font(.system(.title2, design: .rounded)
                    .lowercaseSmallCaps()
            )
            .foregroundColor(.accentColor)
        Divider()
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView()
    }
}
