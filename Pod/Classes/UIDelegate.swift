//
//  UIDelegate.swift
//  Pods
//
//  Created by Daniel Green on 20/06/2015.
//
//

import Foundation

public protocol UIDelegate {
    func showErrorMessage(_ message: String)
}

open class DefaultUIDelegate: UIDelegate {
    open func showErrorMessage(_ message: String) {
        UIAlertView(title: "", message: message, delegate: nil, cancelButtonTitle: "OK").show()
    }
}
