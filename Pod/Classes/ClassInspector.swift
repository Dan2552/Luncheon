//
//  ClassInspector.swift
//  LuncheonProject
//
//  Created by Daniel Green on 20/05/2015.
//  Copyright (c) 2015 Daniel Green. All rights reserved.
//

import ObjectiveC
import UIKit

public enum PropertyType {
    case string
    case date
    case bool
    case int
    case other
}

open class ClassInspector {
    open class func properties(_ classToInspect: AnyClass) -> [String] {
        var count : UInt32 = 0
        let properties = class_copyPropertyList(classToInspect, &count)
        var propertyNames = [String]()
        let propertyCount = Int(count)
        for i in 0..<propertyCount {
            let property : objc_property_t = properties![i]!
            let propertyName = NSString(utf8String: property_getName(property))!
            
            propertyNames.append(propertyName as String)
        }
        free(properties)
        
        if let superclass: AnyClass = classToInspect.superclass() {
            if superclass.conforms(to: Lunch.self) {
                propertyNames += self.properties(superclass)
            }
        }
        
        return propertyNames
    }
    
    open class func propertyTypes(_ classToInspect: AnyClass) -> [String: PropertyType] {
        var count : UInt32 = 0
        let properties = class_copyPropertyList(classToInspect, &count)
        var propertyTypes = [String: PropertyType]()
        let propertyCount = Int(count)
        for i in 0..<propertyCount {
            let property : objc_property_t = properties![i]!
            let propertyName = NSString(utf8String: property_getName(property))!
            let propertyAttr = NSString(utf8String: property_getAttributes(property))!
            
            propertyTypes[propertyName as String] = propertyNameToPropertyType(propertyAttr as String)
        }
        free(properties)
        
        if let superclass: AnyClass = classToInspect.superclass() {
            if superclass.conforms(to: Lunch.self) {
                for (key, value) in self.propertyTypes(superclass) {
                    propertyTypes[key] = value
                }
            }
        }
        
        return propertyTypes
    }
    
    fileprivate class func propertyNameToPropertyType(_ name: String) -> PropertyType {
        if name.hasPrefix("T@\"NSString\"") { return .string }
        if name.hasPrefix("T@\"NSDate\"") { return .date }
        if name.hasPrefix("TB,") { return .bool }
        if name.hasPrefix("Tq,N") || name.hasPrefix("Tl,N") { return .int }
        return .other
    }
}
