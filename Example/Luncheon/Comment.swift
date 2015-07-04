//
//  Comment.swift
//  Luncheon
//
//  Created by Daniel Green on 04/07/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Luncheon

class Comment: NSObject, Lunch {
    dynamic var email: String?
    dynamic var body: String?
    
    required override init() {
        super.init()
    }
}