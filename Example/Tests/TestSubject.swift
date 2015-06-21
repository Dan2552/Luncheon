//
//  TestSubject.swift
//  LuncheonProject
//
//  Created by Daniel Green on 13/05/2015.
//  Copyright (c) 2015 Daniel Green. All rights reserved.
//

import UIKit
import Luncheon

class TestSubject: NSObject, Lunch {
    dynamic var stringProperty: String?
    dynamic var numberProperty: NSNumber?
    
    required override init() {
        super.init()
    }
}