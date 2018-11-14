//
//  HomeScreenAPIEndPoint.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import Foundation

/**
 The enum which holds all possible APIs of the Homescreen. Or this can be used to hold all possible APIs of the whole application. This should be confirming to the EndPointConfiguration protocol so as to enable the NetworkManager to make use of it.
 */
public enum API {
    /**
     The Courses API. Which follows the CourseModel
     - See Also: `CourseModel`
    */
    case Courses
    
    /**
     The HackerNews API. Which follows the HackerNewsModel
     - See Also: `HackerNewsModel`
     */
    case HackerNews
    
    /**
     The Mock API. Which follows the MockModel. This is used for the Unit testing purpose
     - See Also: `MockModel`
     */
    case Mock
}

extension API: EndPointConfiguration {
    
    var baseURL: URL {
        switch self {
        case .Courses:
            guard let pathUrl = APIHelper.getUrl(pathUrl: "CoursesBaseUrl"), let url = URL(string: pathUrl) else { fatalError("baseURL could not be configured.")}
            return url
        case .HackerNews:
            guard let pathUrl = APIHelper.getUrl(pathUrl: "HackerNewsDataBaseUrl"), let url = URL(string: pathUrl) else { fatalError("baseURL could not be configured.")}
            return url
        case .Mock:
            guard let pathUrl = APIHelper.getUrl(pathUrl: "MockBaseUrl"), let url = URL(string: pathUrl) else { fatalError("baseURL could not be configured.")}
            return url
        }
    }
    
    var path: String {
        switch self {
        case .HackerNews:
            guard let pathUrl = APIHelper.getUrl(pathUrl: "HackerNewsDataEndPoint") else { return ""}
            return pathUrl
        case .Courses:
            guard let pathUrl = APIHelper.getUrl(pathUrl: "CoursesEndPoint") else { return ""}
            return pathUrl
        case .Mock:
            guard let pathUrl = APIHelper.getUrl(pathUrl: "MockEndPoint") else { return ""}
            return pathUrl
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .Courses:
            return .get
        case .HackerNews:
            return .get
        case .Mock:
            return .get
        }
    }
    
    var task: DataTask {
        switch self {
        case .Courses:
            return .requestParameters(bodyParameters: nil,
                                      bodyEncoding: .urlEncoding,
                                      urlParameters: nil)
        case .HackerNews:
            return .requestParameters(bodyParameters: nil,
                                      bodyEncoding: .urlEncoding,
                                      urlParameters: ["print":"pretty"])
        case .Mock:
            return .requestParameters(bodyParameters: nil,
                                      bodyEncoding: .urlEncoding,
                                      urlParameters: nil)
        }
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
}


