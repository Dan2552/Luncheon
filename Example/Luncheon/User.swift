//
//  User.swift
//  Luncheon
//
//  Created by Daniel Green on 04/07/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Luncheon

class User: NSObject, Lunch {
    dynamic var name: String?
    
    required override init() {
        super.init()
    }
}