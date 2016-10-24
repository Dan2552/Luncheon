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
    case index
    case show
    case create
    case update
    case destroy
}

func request<T: Lunch>(_ method: Alamofire.HTTPMethod, url: String, parameters: Alamofire.Parameters? = nil, allowEmptyForStatusCodes: [Int] = [], handler: @escaping (_ object: T?, _ collection: [T]?)->()) {
    let headers = Options.headers
    
    if Options.verbose {
        print("LUNCHEON: calling \(method) \(url) with params: \(parameters)")
    }

    let responseHandler: (DataResponse<Any>)->() = { response in
        var handleError = true
        
        if let statusCode = response.response?.statusCode {
            handleError = !allowEmptyForStatusCodes.contains(statusCode)
        }
        
        let value = response.result.value
        
        if handleError {
            if Options.errorHandler(response.result.error,
                                    response.response?.statusCode,
                                    value) {
                return
            }
        }
        
        // Single object
        if let attributes = value as? [String: AnyObject] {
            let model = T()
            model.remote.assignAttributes(attributes)
            
            handler(model, nil)
            
            // Collection
        } else if let collection = value as? [[String : AnyObject]] {
            let models: [T] = collection.map { attributes in
                let model = T()
                model.remote.assignAttributes(attributes)
                return model
            }
            
            handler(nil, models)
            
        } else {
            handler(nil, nil)
        }
    }
    
    Alamofire.request(url,
                      method: method,
                      parameters: parameters,
                      encoding: JSONEncoding.default,
                      headers: headers as HTTPHeaders)
             .responseJSON(completionHandler: responseHandler)
    
//    Alamofire.request(method, url, parameters: parameters, encoding: .JSON, headers: headers).responseJSON { response in
//
//    }
}

open class RemoteClass {
    let subject: Lunch.Type
    var nestedUnder = [String: Any]()
    init(subject: Lunch.Type) {
        self.subject = subject
    }

    func pathForAction(_ action: RESTAction, instance: Lunch) -> String {
        return pathForAction(action, remoteId: instance.remote.id!)
    }

    func pathForAction(_ action: RESTAction, remoteId: Any?) -> String {
        let resourceName = subjectClassName().underscoreCased().pluralize()

        var nesting = ""
        for (model, id) in nestedUnder {
            nesting += "\(model.pluralize())/\(id)/"
        }

        switch action {
        case .show, .update, .destroy:
            assert(remoteId != nil, "You need an remoteId for this action")
            return "\(nesting)\(resourceName)/\(remoteId!)"
        default:
            return "\(nesting)\(resourceName)"
        }
    }

    func urlForAction(_ action: RESTAction, remoteId: Any?) -> String {
        return "\(Options.baseUrl!)/\(pathForAction(action, remoteId: remoteId))"
    }

    // MARK: REST class methods
    
    open func all<T: Lunch>(_ callback: @escaping ([T])->()) {
        let url = urlForAction(.index, remoteId: nil)

        request(.get, url: url) { _, collection in
            callback(collection!)
        }
    }

    open func find<T: Lunch>(_ identifier: NSNumber, _ callback: @escaping (T?) -> ()) {
        find(Int(identifier), callback)
    }
    open func find<T: Lunch>(_ identifier: Int, _ callback: @escaping (T?) -> ()) {
        let url = urlForAction(.show, remoteId: identifier as AnyObject?)

        request(.get, url: url, allowEmptyForStatusCodes: [404]) { object, _ in
            callback(object)
        }
    }
    
    fileprivate func subjectClassName() -> String {
        return String(describing: subject).components(separatedBy: ".").last!
    }
}

open class Remote: NSObject {
    let subject: Lunch
    let subjectClass: Lunch.Type
    var changedAttributes = [String: Any]()
    var isKVOEnabled = false
    private var context = 0
    
    open var id: Any? {
        return subject.value(forKey: remoteIdentifier())
    }

    init(subject: Lunch) {
        self.subject = subject
        self.subjectClass = object_getClass(subject) as! Lunch.Type
    }

    deinit {
        removePropertyObservers()
    }
    
    fileprivate func remoteIdentifier() -> String {
        return subjectClass.remoteIdentifier?() ?? "remoteId"
    }

    open func attributes() -> [String: AnyObject] {
        var attributes = subject.local.attributes()
        attributes["id"] = attributes.removeValue(forKey: remoteIdentifier())
        return (attributes as NSDictionary).underscoreKeys()
    }
    
    open func attributesToSend() -> [String: AnyObject] {
        let attrs = attributes() as NSDictionary
        let only: [String]
        if isKVOEnabled {
            let changes = changedAttributes as NSDictionary
            only = changes.stringKeys()
        } else {
            only = nonNilAttributes()
        }

        let attributesToSend = attrs.only(keys: only) as! [String: AnyObject]

        //TODO: use preferences to determine if underscore or not
        return (attributesToSend as NSDictionary).underscoreKeys()
    }




    // MARK: Associations

    open func associated(_ accociation: Lunch.Type) -> RemoteClass {
        let accociateRemote = RemoteClass(subject: accociation)
        let key = subjectClassName().underscoreCased()
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

    open func isDirty() -> Bool {
        return (!isKVOEnabled && nonNilAttributes().count > 0)
            || (isKVOEnabled && changedAttributes.count > 0)
    }

    open func isChanged(_ propertyName: String) -> Bool {
        if !isKVOEnabled && nonNilAttributes().contains(propertyName.underscoreCased()) {
            return true
        }

        for (key, _) in changedAttributes {
            if key.underscoreCased() == propertyName.underscoreCased() {
                return true
            }
        }

        return false
    }

    open func oldValueFor(_ propertyName: String) -> Any? {
        if let oldValue: Any = changedAttributes[propertyName] {
            return (oldValue is NSNull) ? nil : oldValue
        }
        return nil
    }

    // MARK: Observers
    func addPropertyObservers() {
        if isKVOEnabled { return }
        for property in subject.local.properties() {
            subject.addObserver(self, forKeyPath: property, options: [.new, .old], context: &context)
        }
        isKVOEnabled = true
    }

    func removePropertyObservers() {
        for property in subject.local.properties() {
            subject.removeObserver(self, forKeyPath: property)
        }
        isKVOEnabled = false
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &self.context else { return }
        guard changedAttributes[keyPath!] == nil else { return }
        
        let old = change![NSKeyValueChangeKey.oldKey]
        changedAttributes[keyPath!] = old
    }

    func remoteClassInstance() -> RemoteClass {
        return RemoteClass(subject: subjectClass)
    }



    // MARK: REST instance methods

    open func reload<T: Lunch>(_ callback: @escaping (T?)->()) {
        let url = remoteClassInstance().urlForAction(.show, remoteId: id)

        request(.get, url: url) { object, _ in
            callback(object)
        }
    }


    open func save<T: Lunch>(_ callback: @escaping (T)->()) {
        let action: RESTAction = (id == nil) ? .create : .update
        let url = remoteClassInstance().urlForAction(action, remoteId: id)
        let parameters = attributesToSend()
        let method: Alamofire.HTTPMethod = (action == .create) ? .post : .patch
        
        request(method, url: url, parameters: parameters) { object, _ in
            callback(object!)
        }
    }

    open func destroy<T: Lunch>(_ callback: @escaping (T?)->()) {
        let url = remoteClassInstance().urlForAction(.destroy, remoteId:id)

        request(.delete, url: url) { object, _ in
            callback(object)
        }
    }


    open func assignAttributes(_ attributeChanges: [String: Any]) {
        for (key, value) in attributeChanges {
            assignAttribute(key, withValue: value)
        }
    }
    
    open func assignAttribute(_ attributeName: String, withValue value: Any?) {
        var attributeName = attributeName
        if attributeName == "id" {
            attributeName = remoteIdentifier()
        }
        subject.local.assignAttribute(attributeName, withValue: value)
        addPropertyObservers()
    }
    
    fileprivate func subjectClassName() -> String {
        return String(describing: subjectClass).components(separatedBy: ".").last!
    }
}
