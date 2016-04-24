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
    public static var errorHandler = defaultErrorHandler
    static var headers = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]
    
    public static func setHeader(key: String, value: String) {
        headers[key] = value
    }
}