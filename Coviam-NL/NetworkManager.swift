//
//  NetworkManager.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import Foundation

/**
 The Protocol to be confirmed by the Network Manager. This will make sure that the Network manager or any other classes which makes use of the Network Manager follows the proper protocol mechanism
 */
protocol NetworkRouterProtocol: class {
    
    /** The EndPointConfiguration to make sure the request parameters are following the proper protocol mechanism
     - See Also: `EndPointConfiguration`
    */
    associatedtype EndPoint: EndPointConfiguration
    
    /** The core request method which takes care of returning the data either from the cache or from the origin data source
     - See Also: `NetworkManager`
    */
    func request<T: Decodable>(_ route: EndPoint, shouldCache: Bool, cacheDuration: TimeInterval, completion: @escaping (T?, _ error: String?) -> ())
    
    /// The method which cancels all the running tasks for the shared URLSession
    func cancelAllRequests()
    
    /// The method which cancels one particular task. You need to have the reference of the NetworkManager to cancel a particular task
    func cancel()
}

/**
 The possible response errors and its corresponding messages. Also use this enum for localizaing the messages shown to the user
 */
enum ResponseMessages:String, Error {
    case success
    case authenticationError = "Authentication error. Unauthorized user access"
    case badRequest = "Bad request"
    case serverError = "Internal Server error"
    case outdated = "The url you requested is outdated."
    case failed = "Failed network request"
    case noData = "No response data to decode"
    case unableToDecode = "Unable to decode the response."
    case parametersNil = "Parameters were nil."
    case encodingFailed = "Parameter encoding failed."
    case missingURL = "URL is nil."
}

/**
 The Result enum. Which is used to inform the parser that the API response is successful or not.
 */
enum Result<String> {
    
    /// If the response is successful, the parser will return the Result enum with success case. (Status codes 200 to 299)
    case success
    
    /** The failed response will have the failure case with an associated message. This message can be used to update the user about the actual error
 
     - See Also: `ResponseMessages`
    */
    case failure(String)
}

/**
 The Network Manager class is responsible for making a Request to the given EndPoint. The class also decides whether to hit the API to get the data or to get the data from the local cache.
 
 1. This class is responsible for all network related operations.
 2. The completion of the class method is the Generic model(s) or error
 3. The calling class method should take care of downcasting the Generic model to a specific model it expects for.
 */
class NetworkManager<EndPoint: EndPointConfiguration>: NetworkRouterProtocol {
    
    /// The dataTask what the -request(_:urlRequest:shouldCache:cacheDuration:completion:) is creating. This variable is used to cancel the particular task as well.
    private var dataTask: URLSessionDataTask?
    
    /// The shared Cache. It uses the default properties for now. The Cache can be extended based on the requirements to support the cache size and cache policy
    private var cache = URLCache.shared
    
    /// This variable can be used by the third party frameworks' dependency Injection which has the request with them and wanted to execute the request through Network Manager 
    var urlRequest: URLRequest?
    
    /**
     The request method, which first checks whether the request is redundant. If there is already request in progress, the new request will be blocked.
     
     If the request is not redundant, the next check is, whether to fetch the data from the Cache or from the Origin source. If Cache is not set or expired, the API hit will be made to the Origin source and the data will be supplied as a Generic model. If the Cache is not expired, the data will be supplied from the local Cache.
     
     - Parameter route : The EndPoint (which confirms to the EndPointConfiguration protocol). From this EndPoint, all the request related parameters can be retrieved
     - Parameter shouldCache : A boolean which indicates whether the response to be cached locally or not. The default value is set to false. If this parameter is not set by the calling class, the response will not be cached.
     - Parameter cacheDuration : If the response need to be cached, how long the cache is valid? If the cacheDuration value is not passed, everytime the request will be hitting the origin to fetch the data. Unit of the cacheDuration is in seconds
     
     - Parameter completion : A completion block with the Generic model and the error (if any). Both are options fields
     */
    
    func request<T: Decodable>(_ route: EndPoint, shouldCache: Bool = false, cacheDuration: TimeInterval = 0, completion: @escaping (T?, _ error: String?) -> ()) {
        
        shouldBlockRedundant(api: route, completion: { (shouldBlock) in
            
            if !shouldBlock {
                
                do {
                    
                    let request = try self.getRequest(from: route, urlRequest: self.urlRequest)
                    
                    if let cachedData_ = self.readDataFromCache(forRequest: request, shouldRead: shouldCache) {
                        Logger.log(message: "- - - - - - - - - -  Returning the data from Cache for the request - \(request.url?.absoluteString ?? "") - - - - - - - - - -\n")
                        let cachedData:(models: T?, error: String?) = self.getModels(from: cachedData_)
                        completion(cachedData.models, cachedData.error)
                        return
                    }
                    
                    Logger.log(request: request)
                    
                    let session = URLSession.shared
                    
                    self.dataTask = session.dataTask(with: request, completionHandler: { data, response, error in
                        
                        if error != nil {
                            Logger.log(error: error, errorMessage: nil)
                            completion(nil, "Please check your network connection.")
                            return
                        }
                        
                        if let response = response as? HTTPURLResponse {
                            
                            let result = self.handleNetworkResponse(response)
                            switch result {
                            case .success:
                                
                                Logger.log(message: "- - - - - - - - - -  Returning the data from URL request - \(request.url?.absoluteString ?? "") - - - - - - - - - -\n")
                                
                                self.cacheResponseIfNeeded(response, data, request, shouldCache, cacheDuration)
                                let originData:(models: T?, error: String?) = self.getModels(from: data)
                                completion(originData.models, originData.error)
                                
                            case .failure(let networkFailureError):
                                Logger.log(error: error, errorMessage: networkFailureError)
                                completion(nil, networkFailureError)
                            }
                        }
                    })
                    
                } catch {
                    Logger.log(error: error, errorMessage: error.localizedDescription)
                    completion(nil, error.localizedDescription)
                }
                
                ///Add the route path to task description. This is the identification key used when cancelling the request / when chhcking whether to block the duplicate call or not
                self.dataTask?.taskDescription = route.path
                self.dataTask?.resume()
            }
        })
    }
    
    /**
     The method caches the response in the local cache or in-memory based on the following keys
     
     - Parameter response : The response to be cached locally for the future use
     - Parameter data : The data which will have the actual expected data. With the response, the data should also be captured.
     - Parameter request : The request to which the response and data to be cached. This is the unique key among the multiple local cache data.
     - Parameter shouldCache : A boolean which indicates whether the response to be cached locally or not. The default value is set to false. If this parameter is false, the response will not be cached. This method does nothing if the shouldCache parameter is false
     - Parameter cacheDuration : If the response need to be cached, how long the cache is valid? This cacheDuration is added to the response header as an Expiry Cache-Control.
     */
    fileprivate func cacheResponseIfNeeded(_ response: URLResponse?, _ data: Data?, _ request: URLRequest, _ shouldCache: Bool, _ cacheDuration: TimeInterval) {
        
        if shouldCache {
            var modifiedReponse: URLResponse? = nil
            self.addCacheControlHeader(response, cacheDuration, &modifiedReponse)
            
            let response_ = modifiedReponse ?? response
            
            self.cache.storeCachedResponse(CachedURLResponse(response: response_!, data: data!), for: request)
        }
    }
    
    /**
     This method adds the custom expiry time to the response header when caching it locally
     
     - Parameter response : The response to be cached locally for the future use
     - Parameter cacheDuration : If the response need to be cached, how long the cache is valid? This cacheDuration is added to the response header as an Expiry Cache-Control. This duration is added to the current Date and set it as the Cache Expiry
     - Parameter modifiedReponse : An **inout** parameter, which updates the response to be cached after setting the Expiry header
     */
    fileprivate func addCacheControlHeader(_ response: URLResponse?, _ cacheDuration: TimeInterval, _ modifiedReponse: inout URLResponse?) {
        if let HTTPResponse = response as? HTTPURLResponse {
            
            if var newHeaders = HTTPResponse.allHeaderFields as? [String : String] {
                
                newHeaders["Cache-Control"] = "Expires=\(Date().addingTimeInterval(cacheDuration))"
                
                modifiedReponse = HTTPURLResponse(url: HTTPResponse.url!, statusCode: HTTPResponse.statusCode, httpVersion: "HTTP/1.1", headerFields: newHeaders)
            }
        }
    }
    
    /**
     The method which parses the data and supplies the Generic Data Model(s), which can be downcasted by the expected model(s) by the requesting methods of the API
     
     - Parameter data : The data (either from local Cache / from the origin source) which needs to be converted to the Generic model(s)
     - Returns: A tuple which consists of the Generic model(s) and the error (if any)
     */
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
    
    /**
     A private method which check for the response status codes.
     
     - Parameter response : The HTTPURLResponse to which the check needs to be done.
     - Returns: The Result enum, which tells whether the response is success or a failure. If it is a failure, the failure reason is also passed back.
     - See Also: `Result<String>`
     */
    fileprivate func handleNetworkResponse(_ response: HTTPURLResponse) -> Result<String> {
        switch response.statusCode {
        case 200...299: return .success
        case 401: return .failure(ResponseMessages.authenticationError.rawValue)
        case 402...500: return .failure(ResponseMessages.badRequest.rawValue)
        case 501...599: return .failure(ResponseMessages.serverError.rawValue)
        case 600: return .failure(ResponseMessages.outdated.rawValue)
        default: return .failure(ResponseMessages.failed.rawValue)
        }
    }
    
    /**
     A private method which gives the URL request from the EndPoint. This method will return the URLRequest received from dependency injection if that is not nil.
     
     This method also takes care of adding the necessary headers for different types of requests
     
     - Parameter route : The EndPoint details of an API to for the request.
     - Parameter urlRequest : The URLRequest received from the Third party / custom framework during dependency injection
     - Returns: The URLRequest which will be used to hit the origin to retrieve the data or to retrieve the cached data from local.
     
     - Note: This method can also throw an error back. The calling method should catch and process the error (if thrown)
     */
    fileprivate func getRequest(from route: EndPoint, urlRequest: URLRequest?) throws -> URLRequest {
        
        if let request = urlRequest {
            return request
        }
        
        var request = URLRequest(url: route.baseURL.appendingPathComponent(route.path),
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: 10.0)
        
        request.httpMethod = route.httpMethod.rawValue
        do {
            switch route.task {
            case .request:
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            case .requestParameters(let bodyParameters,
                                    let bodyEncoding,
                                    let urlParameters):
                
                try self.configureParameters(bodyParameters: bodyParameters,
                                             bodyEncoding: bodyEncoding,
                                             urlParameters: urlParameters,
                                             request: &request)
                
            case .requestParametersAndHeaders(let bodyParameters,
                                              let bodyEncoding,
                                              let urlParameters,
                                              let additionalHeaders):
                
                self.addAdditionalHeaders(additionalHeaders, request: &request)
                try self.configureParameters(bodyParameters: bodyParameters,
                                             bodyEncoding: bodyEncoding,
                                             urlParameters: urlParameters,
                                             request: &request)
            }
            return request
        } catch {
            throw error
        }
    }
    
    /**
     This method is responsible to configure the parameters to the request of interest.
     
     - Parameter bodyParameters : The Paramters to be included for the POST request.
     - Parameter bodyEncoding : The type of encoding to be used. This is of type enum -ParameterEncoding
     - Parameter urlParameters : The Url query parameters (if anything needs to be added)
     - Parameter request : An **inout** URLRequest parameter which will modify and set the request back after adding the necessary parameters to the it
     
     - Note: This method can also throw an error back. The calling method should catch and process the error (if thrown)
     */
    fileprivate func configureParameters(bodyParameters: Parameters?,
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
    
    /**
     This method is responsible to add any additional headers to the request
     
     - Parameter additionalHeaders : The additional HTTPHeaders to be added to the request
     - Parameter request : An **inout** URLRequest parameter which will modify and set the request back after adding the necessary additional headers to the it
     
     - Note: This method can also throw an error back. The calling method should catch and process the error (if thrown)
     */
    fileprivate func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    /**
     This method is used to check whether to allow a particular API request or not. The method takes all the running tasks and check whether the new request of interest is already in progress.
     
     - Parameter api : The EndPoint to which we need to call the API
     - Parameter completion : Passes a boolean back saying whether to block the new request or not.
     */
    func shouldBlockRedundant(api: EndPoint, completion: @escaping(_ shouldBlock: Bool) -> Void) {
        
        URLSession.shared.getAllTasks { (tasks) in
            for task in tasks {
                if let description = task.taskDescription, description == api.path && task.state == .running {
                    completion(true)
                }
            }
            completion(false)
        }
    }
    
    /**
     Use this method to read the data from cache. If the caching is set to false, return nil data. Else see if the cache is not expired and return the data. If the cache is expired, return nil
     
     - Parameter request : The request to which we need to retrieve the data from local cache (if the cache is valid)
     - Parameter shouldRead : Whether to retrieve the data from local cache or not
     
     - Returns: The data (or nil) based on the above mentioned parameters
     */
    func readDataFromCache(forRequest request: URLRequest, shouldRead: Bool) -> Data? {
        
        if !shouldRead {
            return nil
            
        } else if let cachedResponse = self.cache.cachedResponse(for: request) {
            
            if let response = cachedResponse.response as? HTTPURLResponse, let cacheControl = response.allHeaderFields["Cache-Control"] as? String {
                let expires = cacheControl.replacingOccurrences(of: "Expires=", with: "")
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
                
                guard let date = dateFormatter.date(from: expires) else {
                    return nil
                }
                
                if (date > Date()) {
                    return cachedResponse.data
                }
            }
        }
        
        return nil
    }
    
    /**
     This method is used to cancel the current task which is initiated by the network manager.
     */
    func cancel() {
        self.dataTask?.cancel()
    }
    
    /**
     This method is used to cancel all the running and suspended tasks.
     */
    func cancelAllRequests() {
        
        URLSession.shared.getAllTasks { (tasks) in
            for task in tasks {
                if task.state == .running || task.state == .suspended {
                    task.cancel()
                }
            }
        }
    }
}




