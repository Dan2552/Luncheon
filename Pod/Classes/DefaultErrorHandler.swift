//
//  DefaultErrorHandler.swift
//  Pods
//
//  Created by Daniel Green on 24/04/2016.
//
//

public let defaultErrorHandler: (error: NSError?, status: Int?, value: AnyObject?)->(Bool) = { error, status, value in
    var message = error?.localizedDescription
    
    message = message ?? railsErrorResponse(status, errors: value)
    
    if let m = message {
        Luncheon.Options.uiHandler.showErrorMessage(m)
        return true
    }
    return false
}

public func railsErrorResponse(status: Int?, errors: AnyObject?) -> String? {
    if status < 300 && status > 199 { return nil }
    if status == 403 { return "You don't have permission to retrieve this resource" }
    if status == 422 {
        if let errors = errors as? [String: [String]] {
            for (key, value) in errors {
                if key == "base" {
                    return "\(value.first!)"
                } else {
                    return "\(key.humanize()) \(value.first!)"
                }
            }
        } else if let errors = errors as? [String: [String: [String]]] {
            if let errorsValue = errors["errors"] {
                return railsErrorResponse(status, errors: errorsValue)
            }
        }
    }
    
    return "An unknown error occured"
}