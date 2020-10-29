//
//  JobStatusRequest.swift

//
//  Created by Ateeb Ahmed on 11/06/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import Foundation

struct JobStatusRequest: Encodable {
    let jobId: Int
    let status: String
}
