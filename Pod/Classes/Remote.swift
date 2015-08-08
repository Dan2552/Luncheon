//
//  File.swift
//  Pods
//
//  Created by Daniel Green on 20/06/2015.
//
//

import Foundation
import Placemat
import Alamofire


public enum RESTAction {
    case INDEX
    case SHOW
    case CREATE
    case UPDATE
    case DESTROY
}

public class RemoteClass {
    let subject: Lunch.Type
    var nestedUnder = [String: Int]()
    init(subject: Lunch.Type) {
        self.subject = subject
    }
    
    func subjectClassNameUnderscore() -> String {
        return NSStringFromClass(subject).componentsSeparatedByString(".").last!.underscoreCase()
    }
    
    func pathForAction(action: RESTAction, instance: Lunch) -> String {
        return self.pathForAction(action, remoteId: instance.remote.id!)
    }
    
    func pathForAction(action: RESTAction, remoteId: Int?) -> String {
        var underscoreName = subjectClassNameUnderscore()
        underscoreName = underscoreName.pluralize()
        
        var nesting = ""
        for (model, id) in nestedUnder {
            nesting += "\(model.pluralize())/\(id)/"
        }
        
        switch action {
        case .SHOW, .UPDATE, .DESTROY:
            assert(remoteId != nil, "You need an remoteId for this action")
            return "\(nesting)\(underscoreName)/\(remoteId!)"
        default:
            return "\(nesting)\(underscoreName)"
        }
    }
    
    func urlForAction(action: RESTAction, remoteId: Int?) -> String {
    Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders?.updateValue("application/json", forKey: "Accept")
        
        return "\(Options.baseUrl!)/\(pathForAction(action, remoteId: remoteId))"
    }
    
    // MARK: REST class methods
    
    public func all<T: Lunch>(callback: ([T])->()) {
        let url = urlForAction(.INDEX, remoteId: nil)
        
        Alamofire.request(.GET, url, parameters: nil, encoding: .JSON).responseJSON { (request, response, result) in
            if result.error != nil {
                Options.errorHandler(error: result.error, statusCode: response?.statusCode, object: nil)
                return
            }
            
            let json = result.value
            if let response = json as? [AnyObject] {
                let models: [T] = response.map { attributes in
                    let model = T()
                    model.assignAttributes(attributes as! [String : AnyObject])
                    return model
                }
                callback(models)
            }
        }
    }
    
    public func find<T: Lunch>(identifier: NSNumber, _ callback: (T?) -> ()) {
        find(Int(identifier), callback)
    }
    public func find<T: Lunch>(identifier: Int, _ callback: (T?) -> ()) {
        let url = urlForAction(.SHOW, remoteId: identifier)
        Alamofire.request(.GET, url, encoding: .JSON).responseJSON { (request, response, result) in
            if result.error != nil {
                Options.errorHandler(error: result.error, statusCode: response?.statusCode, object: nil)
                return
            }
            let json = result.value
            if let response = json as? [String: AnyObject] {
                let model = T()
                model.assignAttributes(response)
                callback(model)
            } else {
                callback(nil)
            }
        }
    }
}

public class Remote: NSObject {
    let subject: Lunch
    var changedAttributes = [String: AnyObject]()
    var isKVOEnabled = false
    
    public var id: Int?
    
    init(subject: Lunch?) {
        self.subject = subject!
    }
    
    deinit {
        removePropertyObservers()
    }
    
    public func subjectClassNameUnderscore() -> String {
        return NSStringFromClass(subjectClass()).componentsSeparatedByString(".").last!.underscoreCase()
    }
    
    func subjectClass() -> Lunch.Type {
        return object_getClass(subject) as! Lunch.Type
    }
    
    func subjectProperties() -> [String] {
        return ClassInspector.properties(subjectClass())
    }
    
    func subjectAttributes() -> [String: AnyObject] {
        var attributes = [String: AnyObject]()
        for property in subjectProperties() {
            if let value = subject.valueForKey(property) {
                attributes[property] = value
            } else {
                attributes[property] = NSNull()
            }
        }
        
        attributes["id"] = self.id

        return attributes
    }
    
    public func attributesToSend() -> [String: AnyObject] {
        let attrs = subjectAttributes() as NSDictionary
        let only: [String]
        if isKVOEnabled {
            let changes = changedAttributes as NSDictionary
            only = changes.stringKeys()
        } else {
            only = nonNilAttributes()
        }
        
        let attributesToSend = attrs.only(only) as! [String: AnyObject]
        
        //TODO: use preferences to determine if underscore or not
        return (attributesToSend as NSDictionary).underscoreKeys()
    }
    
    public func assignSubjectAttribute(attributeName: String, withValue value: AnyObject?) {
        var key = attributeName
        if key == "id", let id = value as? Int {
            self.id = id
            return
        }
        key = key.camelCaseLower()
        
        if subjectProperties().contains(key) {
            subject.setValue(value, forKey: key)
        }
    }
    
    public func assignSubjectAttributes(attributeChanges: [String: AnyObject]) {
        for (key, value) in attributeChanges {
            assignSubjectAttribute(key, withValue: value)
        }
    }
    
    // MARK: Accociations
    
    public func accociated(accociation: Lunch.Type) -> RemoteClass {
        let accociateRemote = RemoteClass(subject: accociation)
        accociateRemote.nestedUnder[subjectClassNameUnderscore()] = id
        return accociateRemote
    }
    
    // MARK: Dirty attributes
    
    func nonNilAttributes() -> [String] {
        var keys = [String]()
        for (key, value) in subjectAttributes() {
            if !(value is NSNull) {
                keys.append(key)
            }
        }
        return keys
    }
    
    // from server:
    // Post(title: "hello")
    //
    
    public func isDirty() -> Bool {
        return (!isKVOEnabled && nonNilAttributes().count > 0)
            || (isKVOEnabled && changedAttributes.count > 0)
    }
    
    public func isChanged(propertyName: String) -> Bool {
        if !isKVOEnabled && nonNilAttributes().contains(propertyName.camelCaseLower()) {
            return true
        }
        
        for (key, _) in changedAttributes {
            if key.camelCaseLower() == propertyName.camelCaseLower() {
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
    
    // MARK: Observers
    func addPropertyObservers() {
        for property in subjectProperties() {
            subject.addObserver(self, forKeyPath: property, options: [.New, .Old], context: nil)
        }
        isKVOEnabled = true
    }
    
    func removePropertyObservers() {
        for property in subjectProperties() {
            subject.removeObserver(self, forKeyPath: property)
        }
        isKVOEnabled = false
    }
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if changedAttributes[keyPath!] != nil { return }
        let old = change!["old"]
        changedAttributes[keyPath!] = old
    }
    
    func remoteClass() -> Remote.Type {
        return object_getClass(self) as! Remote.Type
    }
    
    func remoteClassInstance() -> RemoteClass {
        return RemoteClass(subject: subjectClass())
    }
    

    
    // MARK: REST instance methods
    
    public func reload<T: Lunch>(callback: (T?)->()) {
        let url = remoteClassInstance().urlForAction(.SHOW, remoteId: id)

        Alamofire.request(.GET, url, encoding: .JSON).responseJSON { (request, response, result) in
            if result.error != nil {
                Options.errorHandler(error: result.error, statusCode: response?.statusCode, object: nil)
                return
            }
            
            let json = result.value
            if let response = json as? [String: AnyObject] {
                let model = T()
                model.assignAttributes(response)
                callback(model)
            } else {
                callback(nil)
            }
        }
    }
    
    
    public func save<T: Lunch>(callback: (T)->()) {
        let action: RESTAction = (id == nil) ? .CREATE : .UPDATE
        let url = remoteClassInstance().urlForAction(action, remoteId:id)
        let parameters = attributesToSend()
        let method: Alamofire.Method = (action == .CREATE) ? .POST : .PATCH
        
        print("calling \(method) \(url) with params: \(parameters)")
        Alamofire.request(method, url, parameters: parameters, encoding: .JSON).responseJSON { (request, response, result) in
            if result.error != nil {
                Options.errorHandler(error: result.error, statusCode: response?.statusCode, object: nil)
                return
            }
            
            let json = result.value
            if let response = json as? [String: AnyObject] {
                let model = T()
                model.assignAttributes(response)
                callback(model)
            } else {
                //TODO: call error handler with our own error
            }
        }
    }
    
    public func destroy(callback: () -> ()) {
        let url = remoteClassInstance().urlForAction(.DESTROY, remoteId:id)
        Alamofire.request(.DELETE, url, encoding: .JSON).responseJSON { (request, response, result) in
            if result.error != nil {
                Options.errorHandler(error: result.error, statusCode: response?.statusCode, object: nil)
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