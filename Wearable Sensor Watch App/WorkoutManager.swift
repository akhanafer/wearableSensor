//
//  WorkoutManager.swift
//  Wearable Sensor Watch App
//
//  Created by akhanafer on 2023-08-30.
//

import Foundation
import HealthKit
import CoreLocation
import CoreMotion
import RealmSwift

class WorkoutManager: NSObject, ObservableObject {
    let motionManager = CMMotionManager()
    let locationManager = CLLocationManager()
    var workoutModel: Workout?
    var user: RealmSwift.User?
    var motionTimer: Timer?
    
    var selectedWorkout: Workout.Activity? {
        didSet {
            guard let selectedWorkout = selectedWorkout else { return }
            async {
                await startWorkout()
            }
            motionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true){_ in
                if let data = self.motionManager.accelerometerData {
                    self.workoutModel?.data?.accelerometer.append(
                        Workout_data_accelerometer(
                            timestamp: Date(),
                            accelerometerX: data.acceleration.x,
                            accelerometerY: data.acceleration.y,
                            accelerometerZ: data.acceleration.z
                        )
                    )
                } else {
                    self.workoutModel?.data?.accelerometer.append(
                        Workout_data_accelerometer(
                            timestamp: Date(),
                            accelerometerX: 0,
                            accelerometerY: 0,
                            accelerometerZ: 0
                        )
                    )
                }
            }
        }
    }
    
    @Published var showingSummaryView: Bool = false {
        didSet {
            // Sheet dismissed
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?

    func startWorkout() async{
        do {
            user = try await login()
        } catch {
            print("Error logging in")
        }
        workoutModel = createWorkoutAndUser(user!)
        startHeartDataCollection()
        startIMUDataCollection()
        startLocationDataCollection()
    }
    
    func createWorkoutAndUser(_ user: RealmSwift.User) -> Workout{
        let workoutStartTime: Date = Date()
        
        let workout: Workout = Workout(
            userId: user.id,
            metadata: Workout_metadata(activity: selectedWorkout!),
            startDateTime: workoutStartTime,
            endDateTime: nil,
            data: Workout_data(),
            location: List<Workout_location>()
        )
        
        return workout
    }
    
    func startHeartDataCollection() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = (workoutModel?.metadata!.indoor)! ? .indoor : .outdoor
        
        do{
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            return
        }
        
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        session?.delegate = self
        builder?.delegate = self
        
        // Start the workout session and begin data collection
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate){ (success, error) in
            // The workout has started
            
        }
    }

    func startIMUDataCollection(updateInterval: Double = 0.5) {
        self.motionManager.accelerometerUpdateInterval = updateInterval
        self.motionManager.startAccelerometerUpdates()
    }
    
    func startLocationDataCollection(){
        locationManager.delegate = self
        if (workoutModel?.metadata?.indoor)!{
            workoutModel?.location.append(
                Workout_location(
                    timestamp: Date(),
                    latitude: (locationManager.location?.coordinate.latitude)!,
                    longitude: (locationManager.location?.coordinate.longitude)!
                )
            )
        } else {
            locationManager.distanceFilter = 100
            locationManager.startUpdatingLocation()
        }
    }
    
    func requestAuthorization(){
        // The quantity type to write to the health store
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        // The quantity type to write to read from the health store
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKQuantityType.activitySummaryType()
        ]
        
        // Request authorization for those quantity types
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead){(success, error) in
            // Handle error
            
        }
        
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Mark: - State Control
    
    // The workout session state
    @Published var running = false
    
    func pause() {
        session?.pause()
    }
    
    func resume() {
        session?.resume()
    }
    
    func togglePause() {
        if running == true {
            pause()
        }else {
            resume()
        }
    }
    
    func endWorkout() async{
        session?.end()
        motionManager.stopAccelerometerUpdates()
        showingSummaryView = true
        workoutModel?.endDateTime = Date()
        motionTimer?.invalidate()
        locationManager.stopUpdatingLocation()
        await openSyncedRealm(user: user!, workout: workoutModel!)
    }
    
    // Mark: - Workout Metrics
    @Published var averageHeartRate: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var workout: HKWorkout?
    
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }

        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                let meterUnit = HKUnit.meter()
                self.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
            default:
                return
            }
            
            self.workoutModel?.data?.heart.append(
                Workout_data_heart(timestamp: Date(), heartRate: self.heartRate)
            )
        }
    }
    
    func resetWorkout(){
        selectedWorkout = nil
        builder = nil
        session = nil
        workout = nil
        activeEnergy = 0
        averageHeartRate = 0
        heartRate = 0
        distance = 0
    }
}

// Mark: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }
        
        // Wait for the session to transition states before ending the builder
        if toState == .ended {
            builder?.endCollection(withEnd: date){ (success, error) in
                self.builder?.finishWorkout {(workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
                
            }
        }
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate{
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {return}
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            // Update the published values
            updateForStatistics(statistics)
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
    
    
}

extension WorkoutManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        workoutModel?.location.append(
            Workout_location(
                timestamp: Date(),
                latitude: (locations.first?.coordinate.latitude)!,
                longitude: (locations.first?.coordinate.longitude)!
            )
        )
        
    }
}
