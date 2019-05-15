//
//  JobResponse.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 13/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import Foundation

struct JobResponse: Decodable {
    let success: [JobTrip]
}
