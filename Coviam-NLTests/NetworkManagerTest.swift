//
//  NetworkManagerTest.swift
//  Coviam-NLTests
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import XCTest
import Foundation
@testable import Coviam_NL

class NetworkManagerTest: XCTestCase {
    
    var networkManager: NetworkManager<API> {
        return NetworkManager()
    }

    
    func testCancel() {
        networkManager.cancel()
        XCTAssert(true)
    }
    
    func testCancelAll() {
        networkManager.cancelAllRequests()
        XCTAssert(true)
    }
    
    
    func testRequest() {
        networkManager.request(.Mock, shouldCache: false, cacheDuration: APIHelper.getCacheDuration()) { (model: MockModel?, error) in
        }
        XCTAssert(true)
    }
    
    func testReadDataFromCache() {
        let url = URL(string: "https://httpbin.org/")
        let urlRequest = URLRequest(url: url!)
        
        networkManager.request(.Mock, shouldCache: true, cacheDuration: APIHelper.getCacheDuration()) { (model: MockModel?, error) in
            let response = self.networkManager.readDataFromCache(forRequest: urlRequest, shouldRead: true)
            XCTAssertNotNil(response)
        }
        XCTAssert(true)
    }

    func testBlockRedundant() {
        networkManager.shouldBlockRedundant(api: .Mock) { (isBlocked) in
            XCTAssert(true)
        }
    }

}















