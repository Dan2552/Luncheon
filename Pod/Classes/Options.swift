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
    public static var uiHandler: UIDelegate = DefaultUIDelegate()
    public static var errorHandler: (error: NSError?, statusCode: Int?, object: Lunch?)->() = { error, statusCode, object in
        if let e = error { Luncheon.Options.uiHandler.showErrorMessage(e.localizedDescription) }
    }
}