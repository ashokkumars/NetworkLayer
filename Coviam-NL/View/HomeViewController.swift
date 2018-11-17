//
//  HomeViewController.swift
//  Coviam-NL
//
//  Created by Ashok Kumar S on 12/11/18.
//  Copyright © 2018 Coviam. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    var homePresenter: HomePresenter?
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        
        homePresenter = HomePresenter(delegate: self)
        homePresenter?.getHomeScreenData()
        
        //perform(#selector(createDuplicateRequest), with: nil, afterDelay: 0.1)
        
        //perform(#selector(createDuplicateRequest), with: nil, afterDelay: 0.1)
    }
    
    @objc func createDuplicateRequest() {
        homePresenter?.getHomeScreenData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapCancelButton(_ sender: Any) {
        homePresenter?.cancelRequests()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension HomeViewController: HomePresenterDelegate {
   
    func updateView() {
        DispatchQueue.main.async {
            self.textView.attributedText = self.homePresenter?.attributedText
        }
    }
}
