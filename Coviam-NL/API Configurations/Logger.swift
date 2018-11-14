//
//  Logger.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import UIKit

class Logger: NSObject {

    static func log(request: URLRequest) {
        
        updateViewAndPrint("\n - - - - - - - - - - Request Log START \(request.url?.absoluteString ?? "") - - - - - - - - - - \n")
        defer { updateViewAndPrint("\n - - - - - - - - - -  Request Log END - - - - - - - - - - \n") }
        
        let urlAsString = request.url?.absoluteString ?? ""
        let urlComponents = NSURLComponents(string: urlAsString)
        
        let method = request.httpMethod != nil ? "\(request.httpMethod ?? "")" : ""
        let path = "\(urlComponents?.path ?? "")"
        let query = "\(urlComponents?.query ?? "")"
        let host = "\(urlComponents?.host ?? "")"
        
        var logOutput = """
        \(urlAsString) \n\n
        \(method) \(path)?\(query) HTTP/1.1 \n
        HOST: \(host)\n
        """
        for (key,value) in request.allHTTPHeaderFields ?? [:] {
            logOutput += "\(key): \(value) \n"
        }
        if let body = request.httpBody {
            logOutput += "\n \(NSString(data: body, encoding: String.Encoding.utf8.rawValue) ?? "")"
        }
        
        updateViewAndPrint(urlAsString)
    }
    
    static func log(response: URLResponse?) {
        
        updateViewAndPrint("\n - - - - - - - - - - Response Log START - - - - - - - - - - \n")
        defer { updateViewAndPrint("\n - - - - - - - - - -  Response Log END - - - - - - - - - - \n") }
        
        print(response ?? "Nil resoponse")
    }
    
    static func log(error: Error? = nil, errorMessage: String? = nil) {
        
        updateViewAndPrint("\n - - - - - - - - - - Error Log START - - - - - - - - - - \n")
        defer { updateViewAndPrint("- - - - - - - - - -  Error Log END - - - - - - - - - - \n") }
        
        updateViewAndPrint("\n \(error?.localizedDescription ?? "")")
        updateViewAndPrint("\n \(errorMessage ?? "") \n")
    }
    
    static func log(message: String) {
        updateViewAndPrint(message)
    }
    
    static func updateViewAndPrint(_ message: String) {
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateView"), object: nil, userInfo: ["message": message])
        //print(message)
    }
}




