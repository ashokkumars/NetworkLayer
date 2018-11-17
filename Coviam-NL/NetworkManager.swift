//
//  NetworkManager.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import Foundation

var requestMockingKey = "/stub"

let hackerNewsAPIRequest = Request(endPoint: HackerNewsAPIDetails())

// MARK:- Request Implementation

class Request<EndPoint: EndPointConfiguration> {
    let endPoint: EndPoint
    let session: URLSession
    
    init(endPoint: EndPoint, session: URLSession = .shared) {
        self.endPoint = endPoint
        self.session = session
    }
}

extension Request: RequestProtocol, ResponseProtocol {
    
    func request(withCompletion completion: @escaping ([EndPoint.T]?, String?) -> Void) {
        
        requestData { (data, response, error) in
            
            if let response = response as? HTTPURLResponse {
                
                if self.isUnauthorizedUser(response) {
                
                    self.resolveAuthenticationChallenge(with: hackerNewsAPIRequest.endPoint.urlRequest, for: self.endPoint.urlRequest, shouldCache: self.endPoint.shouldCacheResponse, cacheDuration: self.endPoint.cacheDuration, queue: self.endPoint.queue, dispatchAfter: self.endPoint.dispatchDelay, completion: completion)
                    
                    return
                }
            }
            
            let response_ = self.parseResponse(data, response, error)
            completion(response_.models, response_.error)
            
        }
    }
    
    internal func requestData(withCompletion completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        requestData_(endPoint.urlRequest, shouldCache: endPoint.shouldCacheResponse, cacheDuration: endPoint.cacheDuration, queue: endPoint.queue, dispatchAfter: endPoint.dispatchDelay, withCompletion: completion)
    }
    
    fileprivate func resolveAuthenticationChallenge(with urlRequest: URLRequest, for backupRequest: URLRequest, shouldCache: Bool, cacheDuration: TimeInterval, queue: DispatchQueue, dispatchAfter: TimeInterval, completion: @escaping ([EndPoint.T]?, String?) -> Void) {
        
        reauthenticateUser(with: urlRequest, for: backupRequest, shouldCache: shouldCache, cacheDuration: cacheDuration, queue: queue, dispatchAfter: dispatchAfter) { (data, response, error) in
            
            let response_ = self.parseResponse(data, response, error)
            completion(response_.models, response_.error)
            
        }
    }
    
    func parseResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> (models: [EndPoint.T]?, error: String?) {
        
        if error != nil {
            Logger.log(error: error, errorMessage: nil)
            return(nil, "Please check your network connection.")
        }
        
        if let response = response as? HTTPURLResponse {
            let result = self.handleNetworkResponse(response)
            switch result {
            case .success:
                
                self.cacheResponseIfNeeded(response, data, self.endPoint.urlRequest, self.endPoint.shouldCacheResponse, self.endPoint.cacheDuration)
                
                return(self.convertResponseToModel(data).models, error?.localizedDescription)
                
            case .failure(let networkFailureError):
                
                Logger.log(error: error, errorMessage: networkFailureError)
                return(nil, networkFailureError)
            }
        }
        
        return(nil, ResponseMessages.noData.rawValue)
    }
    
    func convertResponseToModel(_ data: Data?) -> (models: [EndPoint.T]?, error: String?) {
        return endPoint.getModel(from: data)
    }
    
    func isUnauthorizedUser(_ response: HTTPURLResponse?) -> Bool {
        
        if response?.statusCode == 401 {
            return true
        }
        return false
    }
    
    func cancel() {
        
        URLSession.shared.getAllTasks { (tasks) in
            for task in tasks {
                if let description = task.taskDescription, description == self.endPoint.urlRequest.url?.absoluteString {
                    task.cancel()
                }
            }
        }
    }
}

// MARK:- Request Protocol

protocol RequestProtocol {
    
    func requestData(withCompletion completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void)
    
    /// The method which cancels all the running tasks for the shared URLSession
    func cancelAllRequests()
    
    /// The method which cancels one particular task. We need to pass which APIRequest to cancel
    func cancel()
}

extension RequestProtocol where Self : ResponseProtocol {

    func requestData_(_ urlRequest: URLRequest, shouldCache: Bool, cacheDuration: TimeInterval, queue: DispatchQueue, dispatchAfter: TimeInterval, withCompletion completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        
        if isMockRequest(request: urlRequest), let mockData = getMockResponse(for : urlRequest).data {
            Logger.log(message: "- - - - - - - - - -  Returning Mock Response for the request - \(urlRequest.url?.absoluteString ?? "") - - - - - - - - - -\n")
            completion(mockData, HTTPURLResponse(url: urlRequest.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil), nil)
            return
        }
        
        shouldBlockRedundant(urlRequest: urlRequest, completion: { (shouldBlock) in
            
            if !shouldBlock {
                
                let cachedResponse = self.readDataFromCache(forRequest: urlRequest, shouldRead: shouldCache)
                
                if let data = cachedResponse.data {
                    Logger.log(message: "- - - - - - - - - -  Returning the data from Cache for the request - \(urlRequest.url?.absoluteString ?? "") - - - - - - - - - -\n")
                    completion(data, cachedResponse.response, nil)
                    return
                }
                
                Logger.log(request: urlRequest)
                
                self.loadData(with: urlRequest, shouldCache: shouldCache, cacheDuration: cacheDuration, queue: queue, dispatchAfter: dispatchAfter, completion: completion)
            }
            else {
                Logger.log(message: "- - - - - - - - - -  Blocked the redundant URL request - \(urlRequest.url?.absoluteString ?? "")) - - - - - - - - - -\n")
            }
        })
    }
    
    func loadData(with urlRequest: URLRequest, shouldCache: Bool, cacheDuration: TimeInterval, queue: DispatchQueue, dispatchAfter: TimeInterval, completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        
        queue.asyncAfter(deadline: .now() + dispatchAfter, execute: {
            
            let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                completion(data, response, error)
            })
            
            task.taskDescription = urlRequest.url?.absoluteString
            task.resume()
        })
    }
    
    func reauthenticateUser(with urlRequest: URLRequest, for backupRequest: URLRequest, shouldCache: Bool, cacheDuration: TimeInterval, queue: DispatchQueue, dispatchAfter: TimeInterval, completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        
        DispatchQueue.global(qos: .default).async {
            
            let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                
                if error != nil {
                    Logger.log(error: error, errorMessage: nil)
                    completion(nil, nil, error)
                    return
                }
                
                if let response = response as? HTTPURLResponse {
                    let result = self.handleNetworkResponse(response)
                    switch result {
                    case .success:
                        Logger.log(response: response)
                        
                        //Update the header to have the new access token before proceeding with the request
                        self.loadData(with: backupRequest, shouldCache: shouldCache, cacheDuration: cacheDuration, queue: queue, dispatchAfter: dispatchAfter, completion: completion)
                        
                    case .failure(let networkFailureError):
                        Logger.log(error: error, errorMessage: networkFailureError)
                        completion(nil, nil, error)
                    }
                }
            })
            
            task.taskDescription = urlRequest.url?.absoluteString
            task.resume()
        }
    }
    
    func isMockRequest(request: URLRequest) -> Bool {
        
        if let urlString = request.url?.absoluteString, urlString.contains("/stub") {
            return true
        }
        return false
    }
    
    func getMockResponse(for request : URLRequest) -> (data: Data?, response: URLResponse?, error: String?) {
        
        if let urlString = request.url?.absoluteString {
            let urlString_ = urlString.replacingOccurrences(of: requestMockingKey, with: "")
            
            if let responseFileName = URL(string: urlString_)?.lastPathComponent {
                
                let path = Bundle.main.path(forResource: responseFileName, ofType: "json") ?? Bundle.main.path(forResource: "MockResponse", ofType: "json")
                
                if let path_ = path {
                    do {
                        let data = try Data(contentsOf: URL(fileURLWithPath: path_), options: .mappedIfSafe)
                        
                        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)
                        
                        return (data, response, nil)
                        
                    } catch {
                        return (nil, nil, ResponseMessages.noData.rawValue)
                    }
                }
            } else {
                return (nil, nil, ResponseMessages.noData.rawValue)
            }
        }
        return (nil, nil, ResponseMessages.noData.rawValue)
    }
    
    func cancelAllRequests() { }
    
    /**
     This method is used to check whether to allow a particular API request or not. The method takes all the running tasks and check whether the new request of interest is already in progress.
     
     - Parameter api : The EndPoint to which we need to call the API
     - Parameter completion : Passes a boolean back saying whether to block the new request or not.
     */
    func shouldBlockRedundant(urlRequest: URLRequest, completion: @escaping(_ shouldBlock: Bool) -> Void) {
        
        URLSession.shared.getAllTasks { (tasks) in
            
            for task in tasks {
                
                if let description = task.taskDescription, description == urlRequest.url?.absoluteString && task.state == .running {
                    print(#function, tasks.count)
                    completion(true)
                    return
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
    func readDataFromCache(forRequest request: URLRequest, shouldRead: Bool) -> (data: Data?, response: URLResponse?) {
        
        if !shouldRead {
            return (nil, nil)
            
        } else if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
            
            if let response = cachedResponse.response as? HTTPURLResponse, let cacheControl = response.allHeaderFields["Cache-Control"] as? String {
                let expires = cacheControl.replacingOccurrences(of: "Expires=", with: "")
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
                
                guard let date = dateFormatter.date(from: expires) else {
                    return (nil, nil)
                }
                
                if (date > Date()) {
                    return (cachedResponse.data, cachedResponse.response)
                }
            }
        }
        
        return (nil, nil)
    }
}

//MARK:- Network Manager

struct NetworkManager: RequestProtocol {
    
    func requestData(withCompletion completion: @escaping (Data?, URLResponse?, Error?) -> Void) {}
    
    func cancel() {}
    
    func cancelAllRequests() {
        
        URLSession.shared.getTasksWithCompletionHandler({ (tasks, _, _) in
            
            for task in tasks {
                if task.state == .running || task.state == .suspended {
                    task.cancel()
                }
            }
        })
    }
}

// MARK:- Response Protocol

protocol ResponseProtocol: class {
    
    associatedtype R
    
    func convertResponseToModel(_ data: Data?) -> (models: [R]?, error: String?)
    
    func parseResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> (models: [R]?, error: String?)
}

extension ResponseProtocol {
    
    /**
     A private method which check for the response status codes.
     
     - Parameter response : The HTTPURLResponse to which the check needs to be done.
     - Returns: The Result enum, which tells whether the response is success or a failure. If it is a failure, the failure reason is also passed back.
     - See Also: `Result<String>`
     */
    func handleNetworkResponse(_ response: HTTPURLResponse) -> Result<String> {
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
     This method adds the custom expiry time to the response header when caching it locally
     
     - Parameter response : The response to be cached locally for the future use
     - Parameter cacheDuration : If the response need to be cached, how long the cache is valid? This cacheDuration is added to the response header as an Expiry Cache-Control. This duration is added to the current Date and set it as the Cache Expiry
     - Parameter modifiedReponse : An **inout** parameter, which updates the response to be cached after setting the Expiry header
     */
    func addCacheControlHeader(_ response: URLResponse?, _ cacheDuration: TimeInterval, _ modifiedReponse: inout URLResponse?) {
        if let HTTPResponse = response as? HTTPURLResponse {
            
            if var newHeaders = HTTPResponse.allHeaderFields as? [String : String] {
                
                newHeaders["Cache-Control"] = "Expires=\(Date().addingTimeInterval(cacheDuration))"
                
                modifiedReponse = HTTPURLResponse(url: HTTPResponse.url!, statusCode: HTTPResponse.statusCode, httpVersion: "HTTP/1.1", headerFields: newHeaders)
            }
        }
    }
    
    /**
     The method caches the response in the local cache or in-memory based on the following keys
     
     - Parameter response : The response to be cached locally for the future use
     - Parameter data : The data which will have the actual expected data. With the response, the data should also be captured.
     - Parameter request : The request to which the response and data to be cached. This is the unique key among the multiple local cache data.
     - Parameter shouldCache : A boolean which indicates whether the response to be cached locally or not. The default value is set to false. If this parameter is false, the response will not be cached. This method does nothing if the shouldCache parameter is false
     - Parameter cacheDuration : If the response need to be cached, how long the cache is valid? This cacheDuration is added to the response header as an Expiry Cache-Control.
     */
    func cacheResponseIfNeeded(_ response: URLResponse?, _ data: Data?, _ request: URLRequest, _ shouldCache: Bool, _ cacheDuration: TimeInterval) {
        
        if shouldCache, response != nil, data != nil {
            var modifiedReponse: URLResponse? = nil
            self.addCacheControlHeader(response, cacheDuration, &modifiedReponse)
            
            let response_ = modifiedReponse ?? response
            
            URLCache.shared.storeCachedResponse(CachedURLResponse(response: response_!, data: data!), for: request)
        }
    }
}


