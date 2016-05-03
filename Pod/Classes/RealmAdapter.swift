//
//  LunchRealmAdapter.swift
//  Pods
//
//  Created by Daniel Green on 03/05/2016.
//
//

import Foundation
import RealmSwift

public protocol LocalStoreAdapter {
    func all<T : Lunch>(callback: ([T]) -> ())
}

class RealmAdapter: LocalStoreAdapter {
    let realm = try! Realm()
    func all<T : Lunch>(callback: ([T]) -> ()) {
        realm.objects(T)
    }
}