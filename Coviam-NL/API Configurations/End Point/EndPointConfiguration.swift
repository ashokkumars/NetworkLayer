//
//  EndPointConfiguration.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import Foundation

/// This is a default HTTPHeaders of type Dictionary. [String: String]
public typealias HTTPHeaders = [String: String]

/**
 The Protocol to be confirmed by any URLRequest. The URLRequests to be formed by using this protocol variables. Any APIs or EndPoints passed to the NetworkManager should be confirming to this protocol
 */
protocol EndPointConfiguration {
    
    associatedtype T: Decodable
    
    func getModel(from data: Data?) -> (models: [T]?, error: String?)
    
    /// The baseURL of the request. This parameter will be helpful when we have a environment selection (Dev, QA, PAT, UAT etc)
    var baseURL: URL { get }
    
    /// The Url endpoint which should be appended to the baseURL to get the complete Url.
    var path: String { get set }
    
    /** The HTTPMethod. GET / POST / PUT / DELETE etc
     - See Also: `HTTPMethod`
    */
    var httpMethod: HTTPMethod { get }
    
    /** The DataTasks. This includes the cases with different types of requests.
     - See Also: `DataTask`
     */
    var task: DataTask { get }
    
    /** This is a default HTTPHeaders of type Dictionary. [String: String]
     - See Also: `HTTPHeaders`
     */
    var headers: HTTPHeaders? { get }
    
    var shouldCacheResponse: Bool { get }
    
    var cacheDuration: TimeInterval { get }
    
    var queue: DispatchQueue { get }
    
    var dispatchDelay: TimeInterval { get }
    
    var urlRequest: URLRequest { get }
}

extension EndPointConfiguration {
    
    var urlRequest: URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path),
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 10.0)
        request.httpMethod = httpMethod.rawValue
        
        switch task {
        case .request:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .requestParameters(let bodyParameters,
                                let bodyEncoding,
                                let urlParameters):
            
            try? self.configureParameters(bodyParameters: bodyParameters,
                                          bodyEncoding: bodyEncoding,
                                          urlParameters: urlParameters,
                                          request: &request)
            
        case .requestParametersAndHeaders(let bodyParameters,
                                          let bodyEncoding,
                                          let urlParameters,
                                          let additionalHeaders):
            
            self.addAdditionalHeaders(additionalHeaders, request: &request)
            try? self.configureParameters(bodyParameters: bodyParameters,
                                          bodyEncoding: bodyEncoding,
                                          urlParameters: urlParameters,
                                          request: &request)
        }
        
        return request
    }
        
    mutating func mockRequest() {
        path = requestMockingKey
    }
    
    func configureParameters(bodyParameters: Parameters?,
                             bodyEncoding: ParameterEncoding,
                             urlParameters: Parameters?,
                             request: inout URLRequest) throws {
        do {
            try bodyEncoding.encode(urlRequest: &request,
                                    bodyParameters: bodyParameters, urlParameters: urlParameters)
        } catch {
            throw error
        }
    }
    
    func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    func getModel(from data: Data?) -> (models: [T]?, error: String?) {
        return getModels(from: data)
    }
    
    func getModels<T>(from data: Data?) -> (models: T?, error: String?) where T: Decodable {
        
        guard let responseData = data else {
            Logger.log(error: nil, errorMessage: ResponseMessages.noData.rawValue)
            return(nil, ResponseMessages.noData.rawValue)
        }
        do {
            let models = try JSONDecoder().decode(T.self, from: responseData)
            return (models, nil)
            
        } catch {
            Logger.log(error: error, errorMessage: ResponseMessages.unableToDecode.rawValue)
            return(nil, ResponseMessages.unableToDecode.rawValue)
        }
    }
}
