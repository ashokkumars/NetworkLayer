//
//  HackerNewsModel.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import UIKit

/**
 The HackerNewsModel which holds all the expected keys from the response. The model should confirm to the Decodable protocol so that the response can be decoded in a generic way and the Presenter will be able to cast the generic to the HackerNewsModel
 */
class HackerNewsModel: Decodable {
    @objc dynamic var id: Int = 0
    @objc dynamic var descendants: Int = 0
    @objc dynamic var by: String?
    @objc dynamic var score: Int = 0
    @objc dynamic var text: String?
    @objc dynamic var title: String?
    @objc dynamic var type: String?
    @objc dynamic var url: String?
}
