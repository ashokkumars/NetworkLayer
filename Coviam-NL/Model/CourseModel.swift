//
//  DNAModel.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import UIKit

/**
 The CourseModel which holds all the expected keys from the response. The model should confirm to the Decodable protocol so that the response can be decoded in a generic way and the Presenter will be able to cast the generic to the CourseModel
 */
class CourseModel: Decodable {
    @objc dynamic var id: Int = 0
    @objc dynamic var imageUrl: String?
    @objc dynamic var link: String?
    @objc dynamic var name: String?
    @objc dynamic var number_of_lessons: Int = 0
}

