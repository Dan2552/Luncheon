//
//  ClassInspector.swift
//  LuncheonProject
//
//  Created by Daniel Green on 20/05/2015.
//  Copyright (c) 2015 Daniel Green. All rights reserved.
//

import ObjectiveC
import UIKit

class ClassInspector {
    class func properties(classToInspect: AnyClass) -> [String] {
        var count : UInt32 = 0
        let properties : UnsafeMutablePointer <objc_property_t> = class_copyPropertyList(classToInspect, &count)
        var propertyNames = [String]()
        let propertyCount = Int(count)
        for i in 0..<propertyCount {
            let property : objc_property_t = properties[i]
            let propertyName = NSString(UTF8String: property_getName(property))!
            
            //TODO: Use this for attribute type checks
            //let propertyAttr = NSString(UTF8String: property_getAttributes(property))!
            
            propertyNames.append(propertyName as String)
        }
        free(properties)
        
        if let superclass: AnyClass = classToInspect.superclass() {
            if superclass.respondsToSelector(Selector("properties")) {
                let sc = superclass as! Luncheon.Type
                propertyNames += sc.properties()
            }
        }
        
        return propertyNames
    }
}
