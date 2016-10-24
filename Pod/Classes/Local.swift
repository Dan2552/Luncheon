//
//  Local.swift
//  Pods
//
//  Created by Dan on 31/07/2016.
//
//

import Foundation

open class LocalClass {
    init(subject: Lunch.Type) {
        
    }
}

open class Local {
    let subject: Lunch
    let subjectClass: Lunch.Type
    
    init(subject: Lunch) {
        self.subject = subject
        self.subjectClass = object_getClass(subject) as! Lunch.Type
    }
    
    open func properties() -> [String] {
        return ClassInspector.properties(subjectClass)
    }
    
    open func attributes() -> [String: Any] {
        var attributes = [String: Any]()
        for property in properties() {
            if let value = subject.value(forKey: property) {
                attributes[property] = value
            } else {
                attributes[property] = NSNull()
            }
        }

        return attributes
    }
    
    
    open func assignAttributes(_ attributeChanges: [String: Any]) {
        for (key, value) in attributeChanges {
            assignAttribute(key, withValue: value)
        }
    }
    
    open func assignAttribute(_ attributeName: String, withValue value: Any?) {
        var value = value
        if let _ = value as? NSNull { value = nil }
        
        var key = attributeName
        
        key = key.camelCased(firstCharacterCase: .lower)
        
        if properties().contains(key) {
            subject.setValue(value, forKey: key)
        }
    }
}
