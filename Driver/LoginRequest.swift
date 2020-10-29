//
//  LoginRequest.swift

//
//  Created by Ateeb Ahmed on 07/05/2019.
//  Copyright © 2019 Ateeb Ahmed. All rights reserved.
//

import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
    let device_token: String
}
