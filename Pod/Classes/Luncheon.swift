//
//  Luncheon.swift
//  LuncheonProject
//
//  Created by Daniel Green on 20/05/2015.
//  Copyright (c) 2015 Daniel Green. All rights reserved.
//

import UIKit
import Alamofire
import Placemat

//var luncheonBaseUrl: String?
public protocol LuncheonUIDelegate {
    func showErrorMessage(message: String)
}

public class DefaultLuncheonUIDelegate: LuncheonUIDelegate {
    public func showErrorMessage(message: String) {
        UIAlertView(title: "", message: message, delegate: nil, cancelButtonTitle: "OK").show()
    }
}

public class Luncheon: NSObject {
    
    public struct Options {
        public static var baseUrl: String?
        public static var uiHandler: LuncheonUIDelegate = DefaultLuncheonUIDelegate()
        public static var errorHandler: (error: NSError?, statusCode: Int?, object: Luncheon?)->() = { error, statusCode, object in
            if let e = error { Luncheon.Options.uiHandler.showErrorMessage(e.localizedDescription) }
        }
    }
    
    public var remoteId: NSNumber?
    var changedAttributes = [String: AnyObject]()
    
    func luncheonClass() -> Luncheon.Type {
        return object_getClass(self) as! Luncheon.Type
    }
    
    class func luncheonClassNameUnderscore() -> String {
        return NSStringFromClass(self).componentsSeparatedByString(".").last!.underscoreCase()
    }
    
// MARK: Initializers
    
    func setup() {
        addPropertyObservers()
    }
    
    override public init() {
        super.init()
        setup()
    }
    
    required public init(attributes: [String: AnyObject]) {
        super.init()
        setup()
        assignAttributes(attributes)
        changedAttributes = [String: AnyObject]()
    }
    
    deinit {
        removePropertyObservers()
    }

    class func arrayFromAttributesArray(dictionaries: [AnyObject]) -> [Luncheon] {
        var array = [Luncheon]()
        for attributes in dictionaries {
            if let attr = attributes as? [String: AnyObject] {
                array.append(self(attributes: attr))
            }
        }
        return array
    }
    
// MARK: Attributes
    
    class func properties() -> [String] {
        return ClassInspector.properties(self)
    }
    
    public func attributes() -> [String: AnyObject] {
        var attributes = [String: AnyObject]()
        for property in luncheonClass().properties() {
            if var value: AnyObject = valueForKey(property) {
                attributes[property] = value
            } else {
                attributes[property] = NSNull()
            }
        }
        
        if let id = remoteId { attributes["id"] = id }
        
        return attributes
    }

    // Should this be here or a server talking class?
    public func attributesUnderscore(onlyChanged: Bool = false) -> [String: AnyObject] {
        let attributes = onlyChanged ? self.changedAttributes : self.attributes()
        var attributesUnderscore = [String: AnyObject]()
        
        for (key, value) in attributes {
            attributesUnderscore[key.underscoreCase()] = value
        }
        
        return attributesUnderscore
    }
    
    public func assignAttribute(attributeName: String, withValue: AnyObject?) {
        var key = attributeName
        if key == "id" { key = "remote_id" }
        key = key.camelCaseLower()

        if contains(luncheonClass().properties(), key) {
            setValue(withValue, forKey: key)
        }
    }
    
    public func assignAttributes(attributeChanges: [String: AnyObject]) {
        for (key, value) in attributeChanges {
            assignAttribute(key, withValue: value)
        }
    }
    
// MARK: Observers
    func addPropertyObservers() {
        for property in luncheonClass().properties() {
            addObserver(self, forKeyPath: property, options: .New | .Old, context: nil)
        }
    }
    
    func removePropertyObservers() {
        for property in luncheonClass().properties() {
            removeObserver(self, forKeyPath: property)
        }
    }
    
    override public func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if changedAttributes[keyPath] != nil { return }
        
        let old: AnyObject? = change["old"]
        changedAttributes[keyPath] = old
    }
    
// MARK: Dirty attributes
    
    public func isDirty() -> Bool {
        return changedAttributes.count > 0
    }
    
    public func isChanged(propertyName: String) -> Bool {
        for (key, _) in changedAttributes {
            if key.camelCase() == propertyName.camelCase() {
                return true
            }
        }
        return false
    }
    
    public func oldValueFor(propertyName: String) -> AnyObject? {
        if let oldValue: AnyObject = changedAttributes[propertyName] {
            return (oldValue is NSNull) ? nil : oldValue
        }
        return nil
    }
    
// MARK: REST
    
    public enum LuncheonNetworkAction {
        case INDEX
        case SHOW
        case CREATE
        case UPDATE
        case DESTROY
    }
    
    class func pathForAction(action: LuncheonNetworkAction, instance: Luncheon) -> String {
        return self.pathForAction(action, remoteId: instance.remoteId!.integerValue)
    }
    
    class func pathForAction(action: LuncheonNetworkAction, remoteId: NSNumber?) -> String {
        var underscoreName = luncheonClassNameUnderscore()
        underscoreName = underscoreName.pluralize()
        
        switch action {
        case .SHOW, .UPDATE, .DESTROY:
            assert(remoteId != nil, "You need an remoteId for this action")
            return "\(underscoreName)/\(remoteId!)"
        default:
            return underscoreName
        }
    }
    
    class func urlForAction(action: LuncheonNetworkAction, remoteId: NSNumber?) -> String {
        Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders?.updateValue("application/json", forKey: "Accept")

        return "\(Options.baseUrl!)/\(pathForAction(action, remoteId: remoteId))"
    }
    
// MARK: REST class methods
    
    public class func all(callback: ([Luncheon])->()) {
        let url = urlForAction(.INDEX, remoteId: nil)
        
        Alamofire.request(.GET, url, parameters: nil, encoding: .JSON).responseJSON { (request, response, json, error) in
            if error != nil {
                Options.errorHandler(error: error, statusCode: response?.statusCode, object: nil)
                return
            }
            if let response = json as? [AnyObject] {
                let models = self.arrayFromAttributesArray(response)
                callback(models)
            }
        }
    }
    
    public class func find(identifier: Int, _ callback: (Luncheon?) -> ()) {
        let url = urlForAction(.SHOW, remoteId: identifier)
        Alamofire.request(.GET, url, encoding: .JSON).responseJSON { (request, response, json, error) in
            if error != nil {
                Options.errorHandler(error: error, statusCode: response?.statusCode, object: nil)
                return
            }
            
            if let response = json as? [String: AnyObject] {
                let model = self(attributes: response)
                callback(model)
            } else {
                callback(nil)
            }
        }
    }
    
// MARK: REST instance methods
    
    public func reload(callback: (Luncheon?) -> ()) {
        let id = Int(remoteId!)
        let url = luncheonClass().urlForAction(LuncheonNetworkAction.SHOW, remoteId: id)
        
        Alamofire.request(.GET, url, encoding: .JSON).responseJSON { (request, response, json, error) in
            if error != nil {
                Options.errorHandler(error: error, statusCode: response?.statusCode, object: nil)
                return
            }
            
            if let response = json as? [String: AnyObject] {
                let model = self.luncheonClass()(attributes: response)
                callback(model)
            } else {
                callback(nil)
            }
        }
    }
    
    public func save(callback: (Luncheon) -> ()) {
        let action: LuncheonNetworkAction = (remoteId == nil) ? .CREATE : .UPDATE
        let url = luncheonClass().urlForAction(action, remoteId:remoteId)
        
        let parameters = attributesUnderscore(onlyChanged: (action == .UPDATE))
        
        Alamofire.request(.POST, url, parameters: parameters, encoding: .JSON).responseJSON { (request, response, json, error) in
            if error != nil {
                Options.errorHandler(error: error, statusCode: response?.statusCode, object: nil)
                return
            }
            
            if let response = json as? [String: AnyObject] {
                let model = self.luncheonClass()(attributes: response)
                callback(model)
            } else {
                //TODO: call error handler with our own error
            }
        }
    }
    
    public func destroy(callback: () -> ()) {
        let url = luncheonClass().urlForAction(.DESTROY, remoteId:remoteId)
        Alamofire.request(.DELETE, url, encoding: .JSON).responseJSON { (request, response, json, error) in
            if error != nil {
                Options.errorHandler(error: error, statusCode: response?.statusCode, object: nil)
                return
            }
            if response?.statusCode > 399 {
                //TODO
                return
            }
            callback()
        }
    }
    
}
 