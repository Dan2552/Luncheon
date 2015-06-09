//
//  LuncheonRequestTests.swift
//  LuncheonProject
//
//  Created by Daniel Green on 18/05/2015.
//  Copyright (c) 2015 Daniel Green. All rights reserved.
//

import Quick
import Nimble
import Nocilla

class LuncheonRequestSpec: QuickSpec {
    override func spec() {
        
        beforeEach() {
            LSNocilla.sharedInstance().start()
            LuncheonSubclass.Options.baseUrl = "http://example.com"
        }
        
        afterEach() {
            LSNocilla.sharedInstance().stop()
        }
        
        afterSuite() {
            LSNocilla.sharedInstance().clearStubs()
        }
        
        describe("+all") {
            
            it("contains an empty array if there are no objects served from the REST API") {
                stubRequest("GET", "http://example.com/luncheon_subclasses").andReturn(200).withBody("[]")

                var count = -1
                
                LuncheonSubclass.all { objects in
                    count = objects.count
                }
                
                expect(count).toEventually(equal(0))
            }
            
            it("fetches a list of the corresponding object from a REST API") {
                stubRequest("GET", "http://example.com/luncheon_subclasses").andReturn(200).withBody("[ { \"stringProperty\": \"a\" }, { \"stringProperty\": \"b\" } ]")
                
                var count = -1
                
                LuncheonSubclass.all { objects in
                    count = objects.count
                    let o1 = objects[0] as! LuncheonSubclass
                    let o2 = objects[1] as! LuncheonSubclass
                    
                    expect(o1.stringProperty).to(equal("a"))
                    expect(o2.stringProperty).to(equal("b"))
                }
                
                expect(count).toEventually(equal(2))
            }
            
            describe("no internet") {
                it("calls the error handler") {
                    stubRequest("GET", "http://example.com/luncheon_subclasses").andFailWithError(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil))
                    
                    var called = false
                    LuncheonSubclass.Options.errorHandler = { error, _, _ in
                        expect(error!.domain).to(equal(NSURLErrorDomain))
                        expect(error!.code).to(equal(NSURLErrorNotConnectedToInternet))
                        called = true
                    }
                    
                    LuncheonSubclass.all { _ in
                        NSException(name:"nope", reason:"callback should not be called on failed request", userInfo:nil).raise()
                    }
                    
                    expect(called).toEventually(beTrue())
                }
            }
            
        }
        
        describe("+find") {
            
            it("returns a 404 'not found' error if there is no object served from the REST API") {
                stubRequest("GET", "http://example.com/luncheon_subclasses/41").andReturn(404)
                
                var called = false
                
                LuncheonSubclass.find(41) { object in
                    expect(object).to(beNil())
                    called = true
                }
                
                expect(called).toEventually(beTrue())
            }
            
            it("fetches an instance of the corresponding object from a REST API") {
                stubRequest("GET", "http://example.com/luncheon_subclasses/42").andReturn(200).withBody("{ \"stringProperty\": \"a\" }")
                
                var called = false
                
                LuncheonSubclass.find(42) { object in
                    let o = object as! LuncheonSubclass
                    expect(o.stringProperty).to(equal("a"))
                    called = true
                }
                
                expect(called).toEventually(beTrue())
            }
            
        }
        
        describe("-reload") {
            it("refreshes the instance's attributes from the REST API") {
                stubRequest("GET", "http://example.com/luncheon_subclasses/42").andReturn(200).withBody("{ \"stringProperty\": \"a\" }")
                
                let object = LuncheonSubclass()
                object.remoteId = 42
                object.stringProperty = "b"
                
                var called = false
                
                object.reload { object in
                    let o = object as! LuncheonSubclass
                    expect(o.stringProperty).to(equal("a"))
                    called = true
                }
                
                expect(called).toEventually(beTrue())
            }
        }

        describe("-save") {
            
            describe("no id") {
                it("posts the record and we the object returned has an id") {
                    stubRequest("POST", "http://example.com/luncheon_subclasses").andReturn(201).withBody("{ \"id\": 2 }")
                    let object = LuncheonSubclass()
                    
                    var called = false
                    object.save { object in
                        let o = object as! LuncheonSubclass
                        expect(o.remoteId).to(equal(2))
                        called = true
                    }
                    expect(called).toEventually(beTrue())
                }
                
                it("posts all properties that are set") {
                    stubRequest("POST", "http://example.com/luncheon_subclasses").withBody("{\"number_property\":5}").andReturn(201).withBody("{ \"id\": 4 }")
                    
                    var called = false
                    
                    let object = LuncheonSubclass()
                    object.numberProperty = 5
                    object.save { object in
                        let o = object as! LuncheonSubclass
                        expect(o.remoteId).to(equal(4))
                        called = true
                    }
                    
                    expect(called).toEventually(beTrue())
                }
            }
            
            describe("with an id") {
                it("updates existing records") {
                    stubRequest("PATCH", "http://example.com/luncheon_subclasses/3").andReturn(200).withBody("{ \"id\": 3 }")
                    var called = false
                    
                    let object = LuncheonSubclass()
                    object.remoteId = 3
                    
                    object.save { object in
                        let o = object as! LuncheonSubclass
                        expect(o.remoteId).to(equal(3))
                        called = true
                    }
                    expect(called).toEventually(beTrue())
                }
                
                it("updates only dirty properties") {
                    stubRequest("PATCH", "http://example.com/luncheon_subclasses/3").withBody("{\"string_property\":\"updated\"}").andReturn(200).withBody("{ \"id\": 3 }")
                    var called = false
                    
                    let object = LuncheonSubclass()
                    object.remoteId = 3
                    object.stringProperty = "updated"
                    object.save { object in
                        let o = object as! LuncheonSubclass
                        expect(o.remoteId).to(equal(3))
                        called = true
                    }
                    
                    expect(called).toEventually(beTrue())
                }
                
            }
            

        }
        
        describe("-destroy") {
            it("calls to delete the resource") {
                stubRequest("DELETE", "http://example.com/luncheon_subclasses/3").andReturn(204).withBody("")
                var called = false
                
                let object = LuncheonSubclass()
                object.remoteId = 3
                object.destroy {
                    called = true
                }
                
                expect(called).toEventually(beTrue())
            }
        }
        
//      describe("-action") {}
    }
}
