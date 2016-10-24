//
//  PostDetailViewController.swift
//  Luncheon
//
//  Created by Daniel Green on 04/07/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

class PostDetailViewController: UITableViewController {
    var post = Post()
    var comments: [Comment]?
    
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!

    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func viewDidLoad() {
        titleLabel.text = post.title
        bodyLabel.text = post.body
        
        User.remote.find(post.userId!) { (user: User?) in
            self.authorLabel.text = user?.name
        }
        
        post.remote.associated(Comment.self).all { (comments: [Comment]) in
            self.comments = comments
            self.populateComments()
        }
    }
    
    func populateComments() {
        if let c = comments {
            if c.count > 0 {
                commentsLabel.text = "\(c.count) comments"
            } else {
                commentsLabel.text = "No comments"
            }
        }
    }
}
