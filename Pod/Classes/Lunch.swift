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
    
    func value(forKey key: String) -> Any?
    func setValue(_ value: Any?, forKey key: String)
    
    func addObserver(_ observer: NSObject, forKeyPath keyPath: String, options: NSKeyValueObservingOptions, context: UnsafeMutableRawPointer?)
    func removeObserver(_ observer: NSObject, forKeyPath keyPath: String)
    
    @objc optional static func remoteIdentifier() -> String
}

private var remoteAssociationKey: UInt8 = 0
private var localAssociationKey: UInt8 = 1

public extension Lunch {
    static var remote: RemoteClass {
        return RemoteClass(subject: self)
    }

    static var local: LocalClass {
        return LocalClass(subject: self)
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
    
    public var local: Local {
        if let l = objc_getAssociatedObject(self, &localAssociationKey) as? Local {
            return l
        } else {
            let l = Local(subject: self)
            objc_setAssociatedObject(self, &localAssociationKey, l, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return l
        }
    }
}
