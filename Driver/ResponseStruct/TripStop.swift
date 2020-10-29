//
//  TripStop.swift

//
//  Created by Ateeb Ahmed on 13/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import Foundation

struct TripStop: Decodable {
    let id: Int?
    let jobId: String?
    var jobIdInt: Int? {
        return Int(jobId ?? "0")
    }
    let address: String?
    let latitude: String?
    var latitudeDouble: Double? {
        return Double(latitude ?? "0.0")
    }
    let longitude: String?
    var longitudeDouble: Double? {
        return Double(longitude ?? "0.0")
    }
    let status: String?
}
