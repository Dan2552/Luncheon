//
//  ClassInspector.swift
//  LuncheonProject
//
//  Created by Daniel Green on 20/05/2015.
//  Copyright (c) 2015 Daniel Green. All rights reserved.
//

import ObjectiveC
import UIKit

public enum PropertyType: String {
    case NSString = "NSString"
    case NSDate = "NSDate"
    case BOOL = "BOOL"
    case Integer = "Integer"
    case Other = "Other"
}

public class ClassInspector {
    public class func properties(classToInspect: AnyClass) -> [String] {
        var count : UInt32 = 0
        let properties : UnsafeMutablePointer <objc_property_t> = class_copyPropertyList(classToInspect, &count)
        var propertyNames = [String]()
        let propertyCount = Int(count)
        for i in 0..<propertyCount {
            let property : objc_property_t = properties[i]
            let propertyName = NSString(UTF8String: property_getName(property))!
            
            propertyNames.append(propertyName as String)
        }
        free(properties)
        
        if let superclass: AnyClass = classToInspect.superclass() {
            if superclass.conformsToProtocol(Lunch) {
                propertyNames += self.properties(superclass)
            }
        }
        
        return propertyNames
    }
    
    public class func propertyTypes(classToInspect: AnyClass) -> [String: PropertyType] {
        var count : UInt32 = 0
        let properties : UnsafeMutablePointer <objc_property_t> = class_copyPropertyList(classToInspect, &count)
        var propertyTypes = [String: PropertyType]()
        let propertyCount = Int(count)
        for i in 0..<propertyCount {
            let property : objc_property_t = properties[i]
            let propertyName = NSString(UTF8String: property_getName(property))!
            let propertyAttr = NSString(UTF8String: property_getAttributes(property))!
            
            propertyTypes[propertyName as String] = propertyNameToPropertyType(propertyAttr as String)
        }
        free(properties)
        
        if let superclass: AnyClass = classToInspect.superclass() {
            if superclass.conformsToProtocol(Lunch) {
                for (key, value) in self.propertyTypes(superclass) {
                    propertyTypes[key] = value
                }
            }
        }
        
        return propertyTypes
    }
    
    private class func propertyNameToPropertyType(name: String) -> PropertyType {
        if name.hasPrefix("T@\"NSString\"") { return .NSString }
        if name.hasPrefix("T@\"NSDate\"") { return .NSDate }
        if name.hasPrefix("TB,") { return .BOOL }
        if name.hasPrefix("Tq,N") { return .Integer }
        return .Other
    }
}
