//
//  ViewController.swift
//  iOS Assignment
//
//  Created by Atisha Poojary on 22/01/17.
//  Copyright © 2017 Atisha Poojary. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating  {

    @IBOutlet weak var tableView: UITableView!
    var refreshCtrl: UIRefreshControl!
    var tableData:[AnyObject]!
    var dic:Dictionary<String, Any>!
    var nameArray:NSArray!
    var resultArray:NSArray!
    var task: URLSessionDownloadTask!
    var session: URLSession!
    var cache:NSCache<AnyObject, AnyObject>!
    var searchController = UISearchController()
    var ascendingSort: Bool!
    var isSortActive: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        session = URLSession.shared
        task = URLSessionDownloadTask()
        
        self.refreshCtrl = UIRefreshControl()
        self.refreshCtrl.addTarget(self, action: #selector(ViewController.refreshTableView), for: .valueChanged)
        
        self.tableData = []
        self.cache = NSCache()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.loadViewIfNeeded()
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        tableView.tableHeaderView = searchController.searchBar
        
        definesPresentationContext = true
        
        ascendingSort = true
        isSortActive = false
        let sortButton = UIButton(type: .custom)
        sortButton.setImage(UIImage(named: "sort.png") , for: .normal)
        sortButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        sortButton.addTarget(self, action: #selector(ViewController.sort), for: .touchUpInside)
        let buttonItem = UIBarButtonItem(customView: sortButton)
        self.navigationItem.setRightBarButton(buttonItem, animated: true)
        
        self.refreshTableView()
    }
    
    func sort(){
        isSortActive = true
        var descriptor: NSSortDescriptor
        if ascendingSort! {
            descriptor =  NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
            ascendingSort = false
        }
        else{
            descriptor =  NSSortDescriptor(key: "name", ascending: false, selector: #selector(NSString.caseInsensitiveCompare(_:)))
            ascendingSort = true
        }
        self.resultArray = self.nameArray.sortedArray(using: [descriptor]) as NSArray
        print("self.resultArray\(self.resultArray)")
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
    }

    func refreshTableView(){
        let pathToFile = Bundle.main.url(forResource: "ResultsFile", withExtension: "txt")
        
        let url:URL! = URL(string: "https://itunes.apple.com/search?term=League_of_Legends")
        task = session.downloadTask(with: url, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in
            
            if location != nil{
                let data:Data! = try? Data(contentsOf: pathToFile!)
                do{
                    let dic = try JSONSerialization.jsonObject(with: data! as Data, options:.allowFragments)
                    self.dic = dic as! Dictionary
                    self.tableData = (dic as AnyObject).value(forKey : "results") as? [AnyObject]
                    self.nameArray = (dic as AnyObject).value(forKey : "results") as? NSArray
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.tableView.reloadData()
                        self.refreshCtrl?.endRefreshing()
                    })
                }catch{
                    print("something went wrong, try again")
                }
            }
        })
        task.resume()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if searchController.isActive && searchController.searchBar.text != "" {
            return self.resultArray.count
        }
        else {
            if (self.dic != nil){
                return self.tableData.count
            }
        }
        return self.tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:TableViewCell = (self.tableView?.dequeueReusableCell(withIdentifier: "customCell") as! TableViewCell!)
        
        var dictionary: [String:AnyObject]
        if (searchController.isActive && searchController.searchBar.text != "") || isSortActive!{
            if self.resultArray.count != 0 {
                dictionary = self.resultArray[(indexPath as NSIndexPath).row] as! [String:AnyObject]
                if indexPath.row == self.resultArray.count {
                    isSortActive = false
                }
            }
            else{
                return cell
            }
        }
        else{
            if self.tableData != nil {
                dictionary = self.tableData[(indexPath as NSIndexPath).row] as! [String:AnyObject]
            }
            else{
                return cell
            }
        }
        
        cell.trackName.text = dictionary["name"] as? String
        cell.artworkImageView.image = UIImage(named: "placeholder")
        
        if (self.cache.object(forKey: (indexPath as NSIndexPath).row as AnyObject) != nil){
            // Use cache
            cell.artworkImageView?.image = self.cache.object(forKey: (indexPath as NSIndexPath).row as AnyObject) as? UIImage
        }else{
            let artworkUrl = dictionary["image"] as! String
            let url:URL! = URL(string: artworkUrl)
            task = session.downloadTask(with: url, completionHandler: { (location, response, error) -> Void in
                if let data = try? Data(contentsOf: url){
                    DispatchQueue.main.async(execute: { () -> Void in
                        // Before we assign the image, check whether the current cell is visible
                        if let cell:TableViewCell = self.tableView.cellForRow(at: indexPath) as! TableViewCell? {
                            let img:UIImage! = UIImage(data: data)
                            cell.artworkImageView.image = img
                            self.cache.setObject(img, forKey: (indexPath as NSIndexPath).row as AnyObject)
                        }
                    })
                }
            })
            task.resume()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        
        let dictionary = self.tableData[(indexPath as NSIndexPath).row] as! [String:AnyObject]
        vc.imageUrl = dictionary["image"] as? String
        
        self.navigationController?.show(vc, sender: nil)
    }
    
    //MARK: - Search the tableView
    func updateSearchResults(for searchController: UISearchController) {
        if searchController.isActive {
            isSortActive = false
            let searchPredicate = NSPredicate(format: "name CONTAINS[C] %@", searchController.searchBar.text!)
            self.resultArray = self.nameArray.filtered(using: searchPredicate) as NSArray
        }
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

