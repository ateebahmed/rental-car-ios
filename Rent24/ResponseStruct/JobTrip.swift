//
//  File.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 13/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import Foundation

struct JobTrip: Decodable {
    let id: Int
    let rcmId: String?
    var rcmIdInt: Int? {
        return Int(rcmId ?? "0")
    }
    let pickupLocation: String?
    let pickupLat: String?
    var pickupLatDouble: Double? {
        return Double(pickupLat ?? "0.0")
    }
    let pickupLong: String?
    var pickupLongDouble: Double? {
        return Double(pickupLong ?? "0.0")
    }
    let dropoffLocation: String?
    let startTime: String?
    let jobType: String?
    let task: String?
    let dropoffLat: String?
    var dropOffLatDouble: Double? {
        return Double(dropoffLat ?? "0.0")
    }
    let dropoffLong: String?
    var dropOffLongDouble: Double? {
        return Double(dropoffLong ?? "0.0")
    }
    let status: String?
    let route: String?
    let stops: [TripStop]
}
