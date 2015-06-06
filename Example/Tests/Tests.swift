//
//  LuncheonProjectTests.swift
//  LuncheonProjectTests
//
//  Created by Daniel Green on 12/05/2015.
//  Copyright (c) 2015 Daniel Green. All rights reserved.
//

import Quick
import Nimble
import Luncheon

class LuncheonSpec: QuickSpec {
    override func spec() {
    
        var modelSubclass = LuncheonSubclass()

        describe("initWithAttributes:") {
            let attributes = [
                "string_property": "wqijr320",
                "number_property": 35204
            ]
            it("makes a new instance with the given property values") {
                let anotherInstance = LuncheonSubclass(attributes: attributes)
                
                expect(anotherInstance.stringProperty).to(equal("wqijr320"))
                expect(anotherInstance.numberProperty).to(equal(35204))
            }
        }
        
        describe("attributes") {
            it("contains properties defined in the model") {
                expect(modelSubclass.attributes().keys).to(contain("stringProperty"))
                expect(modelSubclass.attributes().keys).to(contain("numberProperty"))
            }
            it("has the values of the properties") {
                modelSubclass.stringProperty = "string property value"
                let attributes = modelSubclass.attributes()
                let stringPropertyValue = attributes["stringProperty"] as! String

                expect(stringPropertyValue).to(equal("string property value"))
            }
            it("returns 'id' for the property 'remote_id'") {
                modelSubclass.remoteId = 324
                let attributes = modelSubclass.attributes()
                let value = attributes["id"] as! Int
                expect(value).to(equal(324))
            }
        }
        
        describe("attributesUnderscore") {
            it("returns the properties defined in the model with underscore keys") {
                expect(modelSubclass.attributesUnderscore().keys).to(contain("string_property"))
                expect(modelSubclass.attributesUnderscore().keys).to(contain("number_property"))
            }
            it("has the values of the properties") {
                modelSubclass.stringProperty = "string property value"
                let attributes = modelSubclass.attributesUnderscore()
                let stringPropertyValue = attributes["string_property"] as! String
                expect(stringPropertyValue).to(equal("string property value"))
            }
            it("returns 'id' for the property 'remote_id'") {
                modelSubclass.remoteId = 324
                let attributes = modelSubclass.attributes()
                let value = attributes["id"] as! Int
                expect(value).to(equal(324))
            }
        }
        
        describe("assignAttribute:") {
            it("sets a property's value using camelCase") {
                modelSubclass.assignAttribute("stringProperty", withValue: "a")
                expect(modelSubclass.stringProperty).to(equal("a"))
            }
            it ("sets a property's value using underscore_case") {
                modelSubclass.assignAttribute("string_property", withValue: "b")
                expect(modelSubclass.stringProperty).to(equal("b"))
            }
            it("sets 'id' property to 'remote_id'") {
                modelSubclass.assignAttribute("id", withValue: 2)
                expect(modelSubclass.remoteId).to(equal(2))
            }
        }
        
        describe("assignAttributes") {
            it("sets many property values using a dictionary") {
                let newValues = [
                    "string_property": "a1",
                    "number_property": 5
                ]
                modelSubclass.assignAttributes(newValues)
                
                expect(modelSubclass.stringProperty).to(equal("a1"))
                expect(modelSubclass.numberProperty).to(equal(5))
            }
            it("sets 'id' property to 'remote_id'") {
                let newValues = [
                    "id": 6
                ] as [String: NSObject]
                modelSubclass.assignAttributes(newValues)
                expect(modelSubclass.remoteId).to(equal(6))
            }
        }
        
    }
}
