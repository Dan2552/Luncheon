//
//  Local.swift
//  Luncheon
//
//  Created by Dan on 01/08/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import Luncheon

class LocalSpec: QuickSpec { override func spec() {
    let subject = TestSubject()
    let local = subject.local
    
    describe("attributes") {
        it("contains properties defined in the model") {
            expect(local.attributes().keys).to(contain("stringProperty"))
            expect(local.attributes().keys).to(contain("numberProperty"))
        }
        it("has the values of the properties") {
            subject.stringProperty = "string property value"
            let attributes = local.attributes()
            let stringPropertyValue = attributes["stringProperty"] as! String
            
            expect(stringPropertyValue).to(equal("string property value"))
        }
        
        it("should not contain changedAttributes") {
            expect(local.attributes().keys).toNot(contain("changedAttributes"))
        }
    }
    
    describe("assignAttributes") {
        it("sets many property values using a dictionary") {
            let newValues = [
                "string_property": "a1",
                "number_property": 5
            ] as [String : Any]
            local.assignAttributes(newValues)
            
            expect(subject.stringProperty).to(equal("a1"))
            expect(subject.numberProperty).to(equal(5))
        }
    }
}}
