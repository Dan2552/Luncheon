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

        let value = response.result.value

        if handleError {
            if Options.errorHandler(error: response.result.error, status: response.response?.statusCode, value: value) {
                return
            }
        }
        
        // Single object
        if let attributes = value as? [String: AnyObject] {
            let model = T()
            model.remote.assignAttributes(attributes)
            
            handler(object: model, collection: nil)
            
        // Collection
        } else if let collection = value as? [[String : AnyObject]] {
            let models: [T] = collection.map { attributes in
                let model = T()
                model.remote.assignAttributes(attributes)
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
    var nestedUnder = [String: AnyObject]()
    init(subject: Lunch.Type) {
        self.subject = subject
    }

    func pathForAction(action: RESTAction, instance: Lunch) -> String {
        return self.pathForAction(action, remoteId: instance.remote.id!)
    }

    func pathForAction(action: RESTAction, remoteId: AnyObject?) -> String {
        let resourceName = subjectClassName().underscoreCase().pluralize()

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

    func urlForAction(action: RESTAction, remoteId: AnyObject?) -> String {
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
    
    private func subjectClassName() -> String {
        return String(subject).componentsSeparatedByString(".").last!
    }
}

public class Remote: NSObject {
    let subject: Lunch
    let subjectClass: Lunch.Type
    var changedAttributes = [String: AnyObject]()
    var isKVOEnabled = false

    public var id: AnyObject? {
        return subject.valueForKey(remoteIdentifier())
    }

    init(subject: Lunch) {
        self.subject = subject
        self.subjectClass = object_getClass(subject) as! Lunch.Type
    }

    deinit {
        removePropertyObservers()
    }
    
    private func remoteIdentifier() -> String {
        return subjectClass.remoteIdentifier?() ?? "remoteId"
    }

    public func attributes() -> [String: AnyObject] {
        var attributes = subject.local.attributes()
        attributes["id"] = attributes.removeValueForKey(remoteIdentifier())
        return (attributes as NSDictionary).underscoreKeys()
    }
    
    public func attributesToSend() -> [String: AnyObject] {
        let attrs = attributes() as NSDictionary
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




    // MARK: Accociations

    public func accociated(accociation: Lunch.Type) -> RemoteClass {
        let accociateRemote = RemoteClass(subject: accociation)
        let key = subjectClassName().underscoreCase()
        accociateRemote.nestedUnder[key] = id
        return accociateRemote
    }

    // MARK: Dirty attributes

    func nonNilAttributes() -> [String] {
        var keys = [String]()
        for (key, value) in attributes() {
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
        if !isKVOEnabled && nonNilAttributes().contains(propertyName.underscoreCase()) {
            return true
        }

        for (key, _) in changedAttributes {
            if key.underscoreCase() == propertyName.underscoreCase() {
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
        if isKVOEnabled { return }
        for property in subject.local.properties() {
            subject.addObserver(self, forKeyPath: property, options: [.New, .Old], context: nil)
        }
        isKVOEnabled = true
    }

    func removePropertyObservers() {
        for property in subject.local.properties() {
            subject.removeObserver(self, forKeyPath: property)
        }
        isKVOEnabled = false
    }

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if changedAttributes[keyPath!] != nil { return }
        let old = change!["old"]
        changedAttributes[keyPath!] = old
    }

    func remoteClassInstance() -> RemoteClass {
        return RemoteClass(subject: subjectClass)
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
        let url = remoteClassInstance().urlForAction(action, remoteId: id)
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


    public func assignAttributes(attributeChanges: [String: AnyObject]) {
        for (key, value) in attributeChanges {
            assignAttribute(key, withValue: value)
        }
    }
    
    public func assignAttribute(attributeName: String, withValue value: AnyObject?) {
        var attributeName = attributeName
        if attributeName == "id" {
            attributeName = remoteIdentifier()
        }
        subject.local.assignAttribute(attributeName, withValue: value)
        addPropertyObservers()
    }
    
    private func subjectClassName() -> String {
        return String(subjectClass).componentsSeparatedByString(".").last!
    }
}
