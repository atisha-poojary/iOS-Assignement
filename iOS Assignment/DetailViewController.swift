//
//  DetailViewController.swift
//  iOS Assignment
//
//  Created by Atisha Poojary on 22/01/17.
//  Copyright © 2017 Atisha Poojary. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    var imageUrl:String!
    @IBOutlet weak var fullImage:UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let url:URL! = URL(string: imageUrl)
        let task: URLSessionDownloadTask = URLSession.shared.downloadTask(with: url, completionHandler: { (location, response, error) -> Void in
            if let data = try? Data(contentsOf: url){
                DispatchQueue.main.async(execute: { () -> Void in
                    let img:UIImage! = UIImage(data: data)
                    self.fullImage.image = img
                })
            }
        })
        task.resume()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
