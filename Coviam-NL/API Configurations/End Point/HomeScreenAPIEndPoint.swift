//
//  HomeScreenAPIEndPoint.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import Foundation

struct CourseAPIDetails: EndPointConfiguration {
    
    var queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated)
    
    var shouldCacheResponse: Bool = false
    
    var cacheDuration: TimeInterval = 0
    
    var dispatchDelay: TimeInterval = 0
    
    var requestEndPoint: String? = APIHelper.getUrl(pathUrl: "CoursesEndPoint")
    
    typealias T = CourseModel
    
    var baseURL: URL {
        guard let pathUrl = APIHelper.getUrl(pathUrl: "CoursesBaseUrl"), let url = URL(string: pathUrl) else { fatalError("baseURL could not be configured.")}
        return url
    }
    
    var path: String {
        get {
            return requestEndPoint ?? ""
        }
        set {
            guard let pathUrl = APIHelper.getUrl(pathUrl: "CoursesEndPoint")
                else {
                    return
            }
            requestEndPoint = pathUrl + newValue
        }
    }
    
    var httpMethod: HTTPMethod {
        return .get
    }
    
    var task: DataTask {
        return .requestParameters(bodyParameters: nil,
                                  bodyEncoding: .urlEncoding,
                                  urlParameters: nil)
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
}


struct HackerNewsAPIDetails: EndPointConfiguration {
    
    var queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated)
    
    var shouldCacheResponse: Bool = false
    
    var cacheDuration: TimeInterval = 0
    
    var dispatchDelay: TimeInterval = 0
    
    typealias T = HackerNewsModel
    
    var requestEndPoint: String? = APIHelper.getUrl(pathUrl: "HackerNewsDataEndPoint")
    
    var baseURL: URL {
        guard let pathUrl = APIHelper.getUrl(pathUrl: "HackerNewsDataBaseUrl"), let url = URL(string: pathUrl) else { fatalError("baseURL could not be configured.")}
        return url
    }
    
    var path: String {
        get {
            return requestEndPoint ?? ""
        }
        set {
            guard let pathUrl = APIHelper.getUrl(pathUrl: "HackerNewsDataEndPoint")
                else {
                    return
            }
            requestEndPoint = pathUrl + newValue
        }
    }
    
    var httpMethod: HTTPMethod {
        return .get
    }
    
    var task: DataTask {
        return .requestParameters(bodyParameters: nil,
                                  bodyEncoding: .urlEncoding,
                                  urlParameters: ["print":"pretty"])
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
    
    func getModel(from data: Data?) -> (models: [T]?, error: String?) {

        guard let responseData = data else {
            Logger.log(error: nil, errorMessage: ResponseMessages.noData.rawValue)
            return(nil, ResponseMessages.noData.rawValue)
        }
        do {
            let models = try JSONDecoder().decode(HackerNewsModel.self, from: responseData)
            return ([models], nil)
            
        } catch {
            Logger.log(error: error, errorMessage: ResponseMessages.unableToDecode.rawValue)
            return(nil, ResponseMessages.unableToDecode.rawValue)
        }
    }
}


