//
//  MockHomePresenter.swift
//  Coviam-NLTests
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import Foundation
import XCTest
@testable import Coviam_NL


class HomePresenterTest: XCTestCase, HomePresenterDelegate {
    func updateView() {
        
    }
    
    func testGetHomeScreenData() {
        let presenter = HomePresenter(delegate: self)
        presenter.getHomeScreenData()
    }
}
