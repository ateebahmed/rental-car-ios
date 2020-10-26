//
//  InvoiceEntry.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 20/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import Foundation

struct InvoiceEntry: Decodable {
    let id: Int?
    let userId: Int?
    let jobId: Int?
    let amount: Float?
    let description: String?
    let images: String?
    let status: String?
}
