//
//  UIDelegate.swift
//  Pods
//
//  Created by Daniel Green on 20/06/2015.
//
//

import Foundation

public protocol UIDelegate {
    func showErrorMessage(message: String)
}

public class DefaultUIDelegate: UIDelegate {
    public func showErrorMessage(message: String) {
        UIAlertView(title: "", message: message, delegate: nil, cancelButtonTitle: "OK").show()
    }
}