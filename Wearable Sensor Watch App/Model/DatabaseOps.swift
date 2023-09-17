//
//  DatabaseOps.swift
//  Wearable Sensor Watch App
//
//  Created by akhanafer on 2023-09-07.
//

import Foundation
import RealmSwift

let app = App(id: "devicesync-oibuc")

func login() async throws -> RealmSwift.User {
    // Authenticate with the instance of the app that points
    // to your backend. Here, we're using anonymous login.
    let user = try await app.login(credentials: Credentials.anonymous)
    print("Successfully logged in user: \(user)")
    return user
}

@MainActor
func openSyncedRealm(user: RealmSwift.User, workout: Workout) async {
    
    do {
        var config = user.flexibleSyncConfiguration(initialSubscriptions: { subs in
            subs.append(
                QuerySubscription<Workout> {
                    $0.userId == user.id
                })
        },
        rerunOnOpen: true)
        // Pass object types to the Flexible Sync configuration
        // as a temporary workaround for not being able to add a
        // complete schema for a Flexible Sync app.
        config.objectTypes = [
            Workout.self,
            Workout_metadata.self,
            Workout_data.self,
            Workout_data_heart.self,
            Workout_data_accelerometer.self,
            Workout_location.self
        ]
        let realm = try await Realm(configuration: config,  downloadBeforeOpen: .always)
        useRealm(realm, user, workout)
    } catch {
        print("Error opening realm: \(error.localizedDescription)")
    }
}

@MainActor
func useRealm(_ realm: Realm, _ user: RealmSwift.User, _ workout: Workout) {
    try! realm.write {
        realm.add(workout)
    }
}
