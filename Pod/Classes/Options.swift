//
//  ClassInspector.swift
//  LuncheonProject
//
//  Created by Daniel Green on 20/05/2015.
//  Copyright (c) 2015 Daniel Green. All rights reserved.
//

import UIKit

public struct Options {
    public static var baseUrl: String?
    public static var verbose = false
    public static var uiHandler: UIDelegate = DefaultUIDelegate()
    public static var errorHandler: (error: NSError?, statusCode: Int?, object: Lunch?)->(Bool) = { error, statusCode, object in
        var message = error?.localizedDescription
        
        if statusCode == 403 { message = message ?? "You don't have permission to retrieve this resource" }
        
        if let m = message {
            Luncheon.Options.uiHandler.showErrorMessage(m)
            return true
        }
        return false
    }
    static var headers = [String: String]()
    
    public static func setHeader(key: String, value: String) {
        headers[key] = value
    }
}