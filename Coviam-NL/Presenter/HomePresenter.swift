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
    var networkManager: NetworkManager<API>
    
    var text: String? = nil
    var attributedText: NSMutableAttributedString?
    
    init(delegate: HomePresenterDelegate) {
        self.delegate = delegate
        self.networkManager = NetworkManager()
    }
    
    func getHomeScreenData() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateView), name: NSNotification.Name(rawValue: "UpdateView"), object: nil)
        
        self.networkManager.request(.Courses) { (models: [CourseModel]?, error) in
            print(models ?? "No models retrieved")
            print(error ?? "Nil error")
        }
        
        self.networkManager.request(.HackerNews, shouldCache: true, cacheDuration: APIHelper.getCacheDuration()) { (model: HackerNewsModel?, error) in
            print(model ?? "No models retrieved")
            print(error ?? "Nil error")
        }
    }
    
    func cancelRequests() {
        networkManager.cancelAllRequests()
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
