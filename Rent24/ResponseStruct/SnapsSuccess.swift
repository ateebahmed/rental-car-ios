//
//  SnapsSuccess.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 26/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import Foundation

struct SnapsSuccess: Decodable {
    let pickup: [String]
    let dropoff: [String]
    let receipt: [String]
}
