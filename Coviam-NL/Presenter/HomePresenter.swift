//
//  HomePresenter.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import UIKit
import Foundation

/**
 This protocol is used only for the testing purpose. In the real application, we can use this for more meaningful purpose
 */
protocol HomePresenterDelegate {
    func updateView()
}

class HomePresenter: NSObject {
    
    var delegate: HomePresenterDelegate
    
    var text: String? = nil
    var attributedText: NSMutableAttributedString?
    
    fileprivate var request: AnyObject?
    
    init(delegate: HomePresenterDelegate) {
        self.delegate = delegate
    }
    
    func getHomeScreenData() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: NSNotification.Name(rawValue: "UpdateView"), object: nil)
        
        let coursesAPIRequest = Request(endPoint: CourseAPIDetails())
        request = coursesAPIRequest
        coursesAPIRequest.request(withCompletion: {(models, error) in
            print(models ?? "No models retrieved")
            print(error ?? "Nil error")
        })
        
        let hackerNewsAPIRequest = Request(endPoint: HackerNewsAPIDetails())
        request = hackerNewsAPIRequest
        hackerNewsAPIRequest.request {(models, error) in
            print(models ?? "No models retrieved")
            print(error ?? "Nil error")
        }
        
        //perform(#selector(cancelRequests), with: nil, afterDelay: 0.1)
        
        //executeMockRequest()
    }
    
    func executeMockRequest() {
        
        print("- - -- - - - - -  Executing a Mock Request - - - - - - - - - ")
        
        var HNAPIDetails = HackerNewsAPIDetails()
        HNAPIDetails.mockRequest()
        
        let hackerNewsMockAPIRequest = Request(endPoint: HNAPIDetails)
        request = hackerNewsMockAPIRequest
        hackerNewsMockAPIRequest.request {(models, error) in
            print("- - -- - - - - -  Mock Response - - - - - - - - - - ")
            print(models ?? "No models retrieved")
            print(error ?? "Nil error")
        }
    }
    
    @objc func cancelRequests() {
        
        let coursesAPIRequest = Request(endPoint: CourseAPIDetails())
        coursesAPIRequest.cancel()
        
        NetworkManager().cancelAllRequests()
    }
    
    @objc func updateView(notification: Notification) {
        
        if let userInfo = notification.userInfo, let message = userInfo["message"] as? String {
            
            let oldText = text ?? ""
            let newText = oldText + message + "\n"
            text = newText
            
            attributedText = NSMutableAttributedString(string: text!)

            delegate.updateView()
        }
    }
}
