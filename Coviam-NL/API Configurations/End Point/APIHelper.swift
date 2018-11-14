//
//  APIHelper.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 14/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import UIKit

/**
 The helper class which is used to support the NetworkManager or any other Requst related classes
 */
class APIHelper: NSObject {

    /**
     This method retrieves the Path Url from the plist file
     
     - Parameter pathUrl : The path name to which we need the Path Url
     - Returns: The pathUrl if found with the mentioned parameter, else returns nil
     */
    static func getUrl(pathUrl: String) -> String? {
        
        if let pathUrl =  getPlistValueFromDict(plistResource: "APIConfiguration", key: pathUrl) as? String {
            return pathUrl
        }
        return nil
    }
    
    static func getPlistDictonary(plistResource: String) -> NSDictionary? {
        
        if let fileUrl = Bundle.main.url(forResource: plistResource, withExtension: "plist"), let data = NSDictionary(contentsOf: fileUrl) {
            return data
        }
        return nil
    }
    
    static func getPlistValueFromDict(plistResource: String, key: String) -> Any? {
        
        if let values = getPlistDictonary(plistResource: plistResource), let value = values[key] {
            return value
        }
        return nil
    }
    
    /**
     This method retrieves the Cache Duration configured in the plist file
     
     - Returns: The time interval which is set in the plist file, else returns 0
     */
    static func getCacheDuration() -> TimeInterval {
        
        if let cacheDuration =  getPlistValueFromDict(plistResource: "APIConfiguration", key: "CacheDuration") as? NSNumber {
            return TimeInterval(truncating: cacheDuration)
        }
        return 0
    }
}
