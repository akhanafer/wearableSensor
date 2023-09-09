//
//  ContentView.swift
//  Wearable Sensor Watch App
//
//  Created by akhanafer on 2023-08-29.
//

import SwiftUI
import HealthKit
struct StartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    var workoutTypes: [Workout.Activity] = [
        .chopping,
        .grating,
        .pouring,
        .wiping,
        .running,
        .cycling,
        .pushups,
        .squats,
        .jumpingJacks,
        .brushing,
        .washingHands,
        .shaving,
        .flushing,
        .eating,
        .drinking,
        .knocking,
        .laughing,
        .coughing,
        .clapping
    ]
    
    var body: some View {
        List(workoutTypes) { workoutType in
            NavigationLink(
                workoutType.name,
                destination: SessionPagingView(),
                tag: workoutType,
                selection: $workoutManager.selectedWorkout
            ).padding(
                EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5)
            )
        }
        .listStyle(.carousel)
        .navigationBarTitle("Workouts")
        .onAppear{
            workoutManager.requestAuthorization()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}
