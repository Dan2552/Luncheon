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
import Luncheon

class LuncheonRequestSpec: QuickSpec {
    override func spec() {
        let defaultHandler = Luncheon.Options.errorHandler
        
        beforeEach() {
            LSNocilla.sharedInstance().start()
            Luncheon.Options.baseUrl = "http://example.com"
        }
        
        afterEach() {
            LSNocilla.sharedInstance().stop()
            Luncheon.Options.errorHandler = defaultHandler
        }
        
        afterSuite() {
            LSNocilla.sharedInstance().clearStubs()
        }
        
        describe("+all") {
            
            it("contains an empty array if there are no objects served from the REST API") {
                stubRequest("GET", "http://example.com/test_subjects")
                    .andReturn(200)
                    .withBody("[]")

                var count = -1
                
                TestSubject.remote.all { (objects: [TestSubject]) in
                    count = objects.count
                }
                
                expect(count).toEventually(equal(0))
            }

            it("fetches a list of the corresponding object from a REST API") {
                stubRequest("GET", "http://example.com/test_subjects")
                    .andReturn(200)
                    .withBody("[ { \"stringProperty\": \"a\" }, { \"stringProperty\": \"b\" } ]")
                
                var count = -1
                
                TestSubject.remote.all { (objects: [TestSubject]) in
                    count = objects.count
                    
                    expect(objects[0].stringProperty).to(equal("a"))
                    expect(objects[1].stringProperty).to(equal("b"))
                }
                
                expect(count).toEventually(equal(2))
            }
            
            describe("no internet") {
                it("calls the error handler") {
                    stubRequest("GET", "http://example.com/test_subjects")
                        .andFailWithError(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil))
                    
                    var called = false
                    Luncheon.Options.errorHandler = { error, _, _ in
                        expect(error!.domain)
                            .to(equal(NSURLErrorDomain))
                        expect(error!.code)
                            .to(equal(NSURLErrorNotConnectedToInternet))
                        called = true
                        
                        return true
                    }
                    
                    TestSubject.remote.all { (_: [TestSubject]) in
                        NSException(name:"nope", reason:"callback should not be called on failed request", userInfo:nil).raise()
                    }
                    
                    expect(called)
                        .toEventually(beTrue())
                }
            }
            
        }
        
        describe("+find") {
            
            it("returns a 404 'not found' error if there is no object served from the REST API") {
                stubRequest("GET", "http://example.com/test_subjects/41")
                    .andReturn(404)
                
                var called = false
                
                TestSubject.remote.find(41) { (object: TestSubject?) in
                    expect(object).to(beNil())
                    called = true
                }
                
                expect(called)
                    .toEventually(beTrue())
            }
            
            it("fetches an instance of the corresponding object from a REST API") {
                stubRequest("GET", "http://example.com/test_subjects/42")
                    .andReturn(200)
                    .withBody("{ \"stringProperty\": \"a\" }")
                
                var called = false
                
                TestSubject.remote.find(42) { (object: TestSubject?) in
                    expect(object?.stringProperty).to(equal("a"))
                    called = true
                }
                
                expect(called)
                    .toEventually(beTrue())
            }
            
        }

        describe("-reload") {
            it("refreshes the instance's attributes from the REST API") {
                stubRequest("GET", "http://example.com/test_subjects/42").andReturn(200).withBody("{ \"stringProperty\": \"a\" }")
                
                let object = TestSubject()
                object.remoteId = 42
                object.stringProperty = "b"
                
                var called = false
                
                object.remote.reload { (object: TestSubject?) in
                    expect(object?.stringProperty).to(equal("a"))
                    called = true
                }
                
                expect(called).toEventually(beTrue())
            }
        }

        describe("-save") {
            
            describe("no id") {
                it("posts the record and we the object returned has an id") {
                    stubRequest("POST", "http://example.com/test_subjects").andReturn(201).withBody("{ \"id\": 2 }")
                    let object = TestSubject()
                    
                    var called = false
                    object.remote.save { (object: TestSubject) in
                        expect(object.remoteId).to(equal(2))
                        called = true
                    }
                    expect(called).toEventually(beTrue())
                }
                
                it("posts all properties that are set") {
                    stubRequest("POST", "http://example.com/test_subjects")
                        .withBody("{\"number_property\":5}")
                        .andReturn(201)
                        .withBody("{ \"id\": 4 }")
                    
                    var called = false
                    
                    let object = TestSubject()
                    object.numberProperty = 5
                    object.remote.save { (object: TestSubject) in
                        expect(object.remoteId).to(equal(4))
                        called = true
                    }
                    
                    expect(called)
                        .toEventually(beTrue())
                }
            }

            describe("with an id") {
                it("updates existing records") {
                    stubRequest("PATCH", "http://example.com/test_subjects/3")
                        .andReturn(200)
                        .withBody("{ \"id\": 3 }")
                    
                    var called = false
                    
                    let object = TestSubject()
                    object.remoteId = 3
                    object.remote.save { (object: TestSubject) in
                        expect(object.remoteId).to(equal(3))
                        called = true
                    }
                    
                    expect(called).toEventually(beTrue())
                }
                
                it("updates only dirty properties") {
                    stubRequest("PATCH", "http://example.com/test_subjects/3")
                        .withBody("{\"id\":3,\"string_property\":\"updated\"}")
                        .andReturn(200).withBody("{\"id\":3,\"string_property\":\"updated\"}")
                    
                    var called = false
                    
                    let object = TestSubject()
                    object.remoteId = 3
                    object.stringProperty = "updated"
                    object.remote.save { (object: TestSubject) in
                        expect(object.remoteId).to(equal(3))
                        called = true
                    }
                    
                    expect(called).toEventually(beTrue())
                }
                
            }
            

        }
        
        describe("-destroy") {
            it("calls to delete the resource") {
                stubRequest("DELETE", "http://example.com/test_subjects/3").andReturn(204).withBody("")
                var called = false
                
                let object = TestSubject()
                object.remoteId = 3
                object.remote.destroy { (_: TestSubject?) in
                    called = true
                }
                
                expect(called).toEventually(beTrue())
            }
        }
        
//      describe("-action") {}
    }
}
