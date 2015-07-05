//
//  ViewController.swift
//  Luncheon
//
//  Created by Daniel Green on 06/06/2015.
//  Copyright (c) 06/06/2015 Daniel Green. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    var posts = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Post.remote.all { (posts: [Post]) in
            self.posts = posts
            self.tableView.reloadData()
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuse", forIndexPath: indexPath) as UITableViewCell
        let post = postFor(indexPath)
        
        cell.textLabel?.text = post.title
        cell.detailTextLabel?.text = post.body

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("post-detail", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController as! PostDetailViewController
        destination.post = postFor(tableView.indexPathForSelectedRow!)
    }
    
    private func postFor(indexPath: NSIndexPath) -> Post {
        return posts[indexPath.row]
    }

}

