//
//  Local.swift
//  Pods
//
//  Created by Daniel Green on 03/05/2016.
//
//

import Foundation

public class LocalClass {
    public func all<T: Lunch>(callback: ([T])->()) {
        Options.localStoreAdapter.all { (collection: [T]) in
            callback(collection)
        }
    }
}

public class Local {
    
}