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
    
    /// The baseURL of the request. This parameter will be helpful when we have a environment selection (Dev, QA, PAT, UAT etc)
    var baseURL: URL { get }
    
    /// The Url endpoint which should be appended to the baseURL to get the complete Url.
    var path: String { get }
    
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
}
