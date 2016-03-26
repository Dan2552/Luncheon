//
//  Lunch.swift
//  Pods
//
//  Created by Daniel Green on 20/06/2015.
//
//

import Foundation

@objc public protocol Lunch {
    init()
    
    func valueForKey(key: String) -> AnyObject?
    func setValue(value: AnyObject?, forKey key: String)
    
    func addObserver(anObserver: NSObject, forKeyPath keyPath: String, options: NSKeyValueObservingOptions, context: UnsafeMutablePointer<Void>)
    func removeObserver(anObserver: NSObject, forKeyPath keyPath: String)
}
private var remoteAssociationKey: UInt8 = 0
public extension Lunch {
    static var remote: RemoteClass {
        return RemoteClass(subject: self)
    }

    static func className() -> String {
        return String(self).componentsSeparatedByString(".").last!
    }
    
    public var remote: Remote {
        if let r = objc_getAssociatedObject(self, &remoteAssociationKey) as? Remote {
            return r
        } else {
            let r = Remote(subject: self)
            objc_setAssociatedObject(self, &remoteAssociationKey, r, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return r
        }
    }
    
    func attributes() -> [String: AnyObject] {
        return remote.subjectAttributes()
    }
    
    func assignAttributes(attributes: [String: AnyObject]) {
        remote.assignSubjectAttributes(attributes)
    }
    
    func assignAttribute(name: String, withValue value: AnyObject?) {
        remote.assignSubjectAttribute(name, withValue: value)
    }
    
    func remoteObject() -> Remote {
        return Remote(subject: self)
    }
}
