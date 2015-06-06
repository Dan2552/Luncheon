//
//  DirtyModelTests.swift
//  LuncheonProject
//
//  Created by Daniel Green on 13/05/2015.
//  Copyright (c) 2015 Daniel Green. All rights reserved.
//

import Quick
import Nimble

class LuncheonDirtySpec: QuickSpec {
    override func spec() {
        
        describe("isChanged:") {
            it("returns true if the given property is changed") {
                var instance = LuncheonSubclass()
                instance.stringProperty = "newValue"
                
                expect(instance.isChanged("stringProperty")).to(equal(true))
            }
            
            it("returns false is the given property is unchanged") {
                var instance = LuncheonSubclass()
                expect(instance.isChanged("stringProperty")).to(equal(false))
            }
        }

        describe("oldValueFor:") {
            it("returns returns the old value if a property is changed") {
                var instance = LuncheonSubclass()
                instance.stringProperty = "value1"
                instance.stringProperty = "value2"
                let oldValue : AnyObject? = instance.oldValueFor("stringProperty")
                expect(oldValue).to(beNil())
            }
        }
        
        describe("isDirty") {
            it("returns true if there are any changes") {
                var instance = LuncheonSubclass()
                instance.stringProperty = "newValue"
                expect(instance.isDirty()).to(equal(true))
            }
            
            it("returns false if no properties are changed") {
                var instance = LuncheonSubclass()
                expect(instance.isDirty()).to(equal(false))
            }
        }
    }
}
