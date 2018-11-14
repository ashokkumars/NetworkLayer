//
//  Mock.swift
//  Coviam-NLTests
//
//  Created by Ratnesh Shukla on 2018-11-14.
//  Copyright © 2018 Coviam. All rights reserved.
//

import Foundation

/**
 The MockModel which holds all the expected keys from the response. The model should confirm to the Decodable protocol so that the response can be decoded in a generic way and the Presenter will be able to cast the generic to the MockModel. This Model is used for the Unit Testing purpose
 */
class MockModel: Decodable {
    @objc dynamic var id: Int = 0
    @objc dynamic var descendants: Int = 0
    @objc dynamic var by: String?
    @objc dynamic var score: Int = 0
    @objc dynamic var text: String?
    @objc dynamic var title: String?
    @objc dynamic var type: String?
    @objc dynamic var url: String?
}
