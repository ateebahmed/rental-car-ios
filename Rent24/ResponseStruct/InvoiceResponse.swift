//
//  InvoiceResponse.swift
//  Rent24
//
//  Created by Ateeb Ahmed on 20/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import Foundation

struct InvoiceResponse: Decodable {
    let success: [InvoiceEntry]?
}
