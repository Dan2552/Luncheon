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

func request<T: Lunch>(method: Alamofire.Method, url: String, parameters: [String: AnyObject]? = nil, allowEmptyForStatusCodes: [Int] = [], handler: (object: T?, collection: [T]?)->()) {
    let headers = Options.headers
    
    if Options.verbose {
        print("LUNCHEON: calling \(method) \(url) with params: \(parameters)")
    }
    
    Alamofire.request(method, url, parameters: parameters, encoding: .JSON, headers: headers).responseJSON { response in
        var handleError = true
        
        if let statusCode = response.response?.statusCode {
            handleError = !allowEmptyForStatusCodes.contains(statusCode)
        }
        
        if let error = response.result.error where handleError {
            Options.errorHandler(error: error, statusCode: response.response?.statusCode, object: nil)
            return
        }
        
        let value = response.result.value

        // Single object
        if let attributes = value as? [String: AnyObject] {
            let model = T()
            model.assignAttributes(attributes)
            
            handler(object: model, collection: nil)
            
        // Collection
        } else if let collection = value as? [[String : AnyObject]] {
            let models: [T] = collection.map { attributes in
                let model = T()
                model.assignAttributes(attributes)
                return model
            }
            
            handler(object: nil, collection: models)
    
        } else {
            handler(object: nil, collection: nil)
        }
    }
}

public class RemoteClass {
    let subject: Lunch.Type
    var nestedUnder = [String: Int]()
    init(subject: Lunch.Type) {
        self.subject = subject
    }

    func pathForAction(action: RESTAction, instance: Lunch) -> String {
        return self.pathForAction(action, remoteId: instance.remote.id!)
    }

    func pathForAction(action: RESTAction, remoteId: Int?) -> String {
        let resourceName = subject.className().underscoreCase().pluralize()

        var nesting = ""
        for (model, id) in nestedUnder {
            nesting += "\(model.pluralize())/\(id)/"
        }

        switch action {
        case .SHOW, .UPDATE, .DESTROY:
            assert(remoteId != nil, "You need an remoteId for this action")
            return "\(nesting)\(resourceName)/\(remoteId!)"
        default:
            return "\(nesting)\(resourceName)"
        }
    }

    func urlForAction(action: RESTAction, remoteId: Int?) -> String {
    Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders?.updateValue("application/json", forKey: "Accept")

        return "\(Options.baseUrl!)/\(pathForAction(action, remoteId: remoteId))"
    }

    // MARK: REST class methods
    
    public func all<T: Lunch>(callback: ([T])->()) {
        let url = urlForAction(.INDEX, remoteId: nil)
        
        request(.GET, url: url) { _, collection in
            callback(collection!)
        }
    }

    public func find<T: Lunch>(identifier: NSNumber, _ callback: (T?) -> ()) {
        find(Int(identifier), callback)
    }
    public func find<T: Lunch>(identifier: Int, _ callback: (T?) -> ()) {
        let url = urlForAction(.SHOW, remoteId: identifier)

        request(.GET, url: url, allowEmptyForStatusCodes: [404]) { object, _ in
            callback(object)
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
        let key = subject.dynamicType.className().underscoreCase()
        accociateRemote.nestedUnder[key] = id
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

        request(.GET, url: url) { object, _ in
            callback(object)
        }
    }


    public func save<T: Lunch>(callback: (T)->()) {
        let action: RESTAction = (id == nil) ? .CREATE : .UPDATE
        let url = remoteClassInstance().urlForAction(action, remoteId:id)
        let parameters = attributesToSend()
        let method: Alamofire.Method = (action == .CREATE) ? .POST : .PATCH
        
        request(method, url: url, parameters: parameters) { object, _ in
            callback(object!)
        }
    }

    public func destroy<T: Lunch>(callback: (T?)->()) {
        let url = remoteClassInstance().urlForAction(.DESTROY, remoteId:id)

        request(.DELETE, url: url) { object, _ in
            callback(object)
        }
    }
}
