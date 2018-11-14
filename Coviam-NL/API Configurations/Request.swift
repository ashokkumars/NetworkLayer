//
//  Request.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 14/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import Foundation

/**
 The default Request Parameters of type Dictionary [String: Any]
 */
public typealias Parameters = [String: Any]

/**
 Different HTTPMethods supported by the application. Extend this by adding PUT, DELETE and other necessary HTTPMethods
 */
public enum HTTPMethod : String {
    case post    = "POST"
    case get     = "GET"
}

/**
 Keeps track of different types of DataTasks needed for the application. Increase number of cases to include the UploadTask, DownloadTask etc based on the requirements
 */
public enum DataTask {
    case request
    
    case requestParameters(bodyParameters: Parameters?,
        bodyEncoding: ParameterEncoding,
        urlParameters: Parameters?)
    
    case requestParametersAndHeaders(bodyParameters: Parameters?,
        bodyEncoding: ParameterEncoding,
        urlParameters: Parameters?,
        additionHeaders: HTTPHeaders?)
}

/**
 The ParameterEncoder protocol, to be confirmed by the request and response parameter encoding classes / structs
 */
public protocol ParameterEncoder {
    func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws
}

/**
 Manages different encoding methods. Extend the cases if more distinct types of encoding is needed
 */
public enum ParameterEncoding {
    
    /// Encodes the Url query parameters
    case urlEncoding
    
    /// Encodes the request body parameters
    case jsonEncoding
    
    /// Encodes both query parameters and the body parameters of a request
    case urlAndJsonEncoding
    
    public func encode(urlRequest: inout URLRequest,
                       bodyParameters: Parameters?,
                       urlParameters: Parameters?) throws {
        do {
            switch self {
            case .urlEncoding:
                guard let urlParameters = urlParameters else { return }
                try URLParameterEncoder().encode(urlRequest: &urlRequest, with: urlParameters)
                
            case .jsonEncoding:
                guard let bodyParameters = bodyParameters else { return }
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: bodyParameters)
                
            case .urlAndJsonEncoding:
                guard let bodyParameters = bodyParameters,
                    let urlParameters = urlParameters else { return }
                try URLParameterEncoder().encode(urlRequest: &urlRequest, with: urlParameters)
                try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: bodyParameters)
                
            }
        }catch {
            throw error
        }
    }
}

/**
 The Request query parameter encoder which confirms to the ParameterEncoder protocol.
 
 - See Also: `ParameterEncoder`
 */
public struct URLParameterEncoder: ParameterEncoder {
    public func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws {
        
        guard let url = urlRequest.url else { throw ResponseMessages.missingURL }
        
        if var urlComponents = URLComponents(url: url,
                                             resolvingAgainstBaseURL: false), !parameters.isEmpty {
            
            urlComponents.queryItems = [URLQueryItem]()
            
            for (key,value) in parameters {
                let queryItem = URLQueryItem(name: key,
                                             value: "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
                urlComponents.queryItems?.append(queryItem)
            }
            urlRequest.url = urlComponents.url
        }
        
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        
    }
}

/**
 The Request body parameter encoder which confirms to the ParameterEncoder protocol.
 
 - See Also: `ParameterEncoder`
 */
public struct JSONParameterEncoder: ParameterEncoder {
    public func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws {
        do {
            let jsonAsData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            urlRequest.httpBody = jsonAsData
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }catch {
            throw ResponseMessages.encodingFailed
        }
    }
}


