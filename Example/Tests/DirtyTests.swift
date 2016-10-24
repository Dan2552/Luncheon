//
//  DirtyModelTests.swift
//  LuncheonProject
//
//  Created by Daniel Green on 13/05/2015.
//  Copyright (c) 2015 Daniel Green. All rights reserved.
//

import Quick
import Nimble

class RemoteDirtySpec: QuickSpec {
    override func spec() {
        
        describe("isChanged:") {
            it("returns true if the given property is changed") {
                let instance = TestSubject()
                instance.stringProperty = "newValue"
                
                expect(instance.remote.isChanged("stringProperty")).to(equal(true))
            }
            
            it("returns false is the given property is unchanged") {
                let instance = TestSubject()
                expect(instance.remote.isChanged("stringProperty")).to(equal(false))
            }
        }

        describe("oldValueFor:") {
            it("returns returns the old value if a property is changed") {
                let instance = TestSubject()
                instance.stringProperty = "value1"
                instance.stringProperty = "value2"
                let oldValue = instance.remote.oldValueFor("stringProperty")
                expect(oldValue).to(beNil())
            }
        }
        
        describe("isDirty") {
            it("returns true if there are any changes") {
                let instance = TestSubject()
                instance.stringProperty = "newValue"
                expect(instance.remote.isDirty()).to(equal(true))
                
            }
            
            it("returns false if no properties are changed") {
                let instance = TestSubject()
                expect(instance.remote.isDirty()).to(equal(false))
            }
        }
        
        describe("attributesToSend") {
            it("contains only attributes that are changed") {
                let instance = TestSubject()
                instance.stringProperty = "hello"
                
                expect(instance.remote.attributesToSend().keys.contains("string_property")).to(equal(true))
                expect(instance.remote.attributesToSend().keys).toNot(contain("number_property"))
            }
            
            it("makes the attribute keys underscore") {
                let instance = TestSubject()
                instance.stringProperty = "hello"
                
                expect(instance.remote.attributesToSend().keys).to(contain("string_property"))

            }
        }
    }
}
