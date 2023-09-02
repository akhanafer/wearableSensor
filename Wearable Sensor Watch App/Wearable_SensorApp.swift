//
//  Wearable_SensorApp.swift
//  Wearable Sensor Watch App
//
//  Created by akhanafer on 2023-08-29.
//

import SwiftUI

@main
struct Wearable_Sensor_Watch_AppApp: App {
    @StateObject var workoutManager = WorkoutManager()
    var body: some Scene {
        WindowGroup {
            NavigationView{
                StartView()
            }
            .sheet(isPresented: $workoutManager.showingSummaryView){
                SummaryView()
            }
            .environmentObject(workoutManager)
        }
        
    }
}
