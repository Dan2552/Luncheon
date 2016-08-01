//
//  Local.swift
//  Pods
//
//  Created by Dan on 31/07/2016.
//
//

import Foundation

public class LocalClass {
    init(subject: Lunch.Type) {
        
    }
}

public class Local {
    let subject: Lunch
    let subjectClass: Lunch.Type
    
    init(subject: Lunch) {
        self.subject = subject
        self.subjectClass = object_getClass(subject) as! Lunch.Type
    }
    
    func properties() -> [String] {
        return ClassInspector.properties(subjectClass)
    }
    
    public func attributes() -> [String: AnyObject] {
        var attributes = [String: AnyObject]()
        for property in properties() {
            if let value = subject.valueForKey(property) {
                attributes[property] = value
            } else {
                attributes[property] = NSNull()
            }
        }
        
//        attributes["id"] = self.id
        
        return attributes
    }
    
    
    public func assignAttributes(attributeChanges: [String: AnyObject]) {
        for (key, value) in attributeChanges {
            assignAttribute(key, withValue: value)
        }
    }
    
    public func assignAttribute(attributeName: String, withValue value: AnyObject?) {
        var value = value
        if let _ = value as? NSNull { value = nil }
        
        var key = attributeName
//        if key == "id", let id = value as? Int {
//            self.id = id
//            return
//        }
        key = key.camelCaseLower()
        
        if properties().contains(key) {
            subject.setValue(value, forKey: key)
        }
    }
}