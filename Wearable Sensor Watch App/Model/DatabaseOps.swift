//
//  DatabaseOps.swift
//  Wearable Sensor Watch App
//
//  Created by akhanafer on 2023-09-07.
//

import Foundation
import RealmSwift

let realm = try! Realm()

func saveWorkout(workout: Workout){
    do {
        try realm.write {
            realm.add(workout)
        }
    } catch let error as NSError {
        print("Error while writing workout: \(error)")
    }
}
