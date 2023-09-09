//
//  Workout.swift
//  Wearable Sensor Watch App
//
//  Created by akhanafer on 2023-09-07.
//

import Foundation
import HealthKit
import CoreLocation
import RealmSwift

class User: Object, Identifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var email: String

    convenience init(name: String, email: String) {
        self.init()
        self.name = name
        self.email = email
    }
}

class Metadata: Object {
    @Persisted var activity: Workout.Activity
    @Persisted var category: Workout.Category
    
    convenience init(activity: Workout.Activity) {
        self.init()
        self.activity = activity
        self.category = {
            switch activity {
            case .chopping, .grating, .pouring, .wiping:
                return .kitchen
            case .running, .cycling, .pushups, .squats, .jumpingJacks:
                return .workout
            case .brushing, .washingHands, .shaving, .flushing:
                return .bathroom
            case .eating, .drinking, .knocking, .laughing, .coughing, .clapping:
                return .miscellaneous
            }
        }()
    }
}

class Data: Object {
    @Persisted var timestamp: Date
    @Persisted var heartRate: Double
    @Persisted var accelerometerX: Double
    @Persisted var accelerometerY: Double
    @Persisted var accelerometerZ: Double
    
    convenience init(timestamp: Date, heartRate: Double, accelerometerX: Double, accelerometerY: Double, accelerometerZ: Double) {
        self.init()
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.accelerometerX = accelerometerX
        self.accelerometerY = accelerometerY
        self.accelerometerZ = accelerometerZ
    }
}

class Workout: Object, Identifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var user: User?
    @Persisted var metadata: Metadata?
    @Persisted var startDateTime: Date
    @Persisted var endDateTime: Date?
    @Persisted var data: List<Data>
    
    convenience init(user: User, metadata: Metadata, startDateTime: Date, endDateTime: Date? = nil, data: List<Data>) {
        self.init()
        self.user = user
        self.metadata = metadata
        self.startDateTime = startDateTime
        self.endDateTime = endDateTime
        self.data = data
    }
    
    enum Category: String, PersistableEnum {
        case kitchen
        case workout
        case bathroom
        case miscellaneous
    }
    
    enum Activity: Int, PersistableEnum, Identifiable {
        case chopping, grating, pouring, wiping // kitchen
        case running, cycling, pushups, squats, jumpingJacks // workout
        case brushing, washingHands, shaving, flushing // bathroom
        case eating, drinking, knocking, laughing, coughing, clapping // misc
        var id: RawValue {rawValue}
        var name: String {
            switch self {
            case .chopping:
                return "Chop"
            case .grating:
                return "Grate"
            case .pouring:
                return "Pour"
            case .wiping:
                return "Wipe"
            case .running:
                return "Run"
            case .cycling:
                return "Bike"
            case .pushups:
                return "Push Ups"
            case .squats:
                return "Squat"
            case .jumpingJacks:
                return "Jumping Jacks"
            case .brushing:
                return "Brush"
            case .washingHands:
                return "Wash"
            case .shaving:
                return "Shave"
            case .flushing:
                return "Flush"
            case .eating:
                return "Eat"
            case .drinking:
                return "Drink"
            case .knocking:
                return "Knock"
            case .laughing:
                return "Laugh"
            case .coughing:
                return "Cough"
            case .clapping:
                return "Clap"
            }
        }
    }
}
