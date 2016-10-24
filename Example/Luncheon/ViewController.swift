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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuse", for: indexPath) as UITableViewCell
        let post = postFor(indexPath)

        cell.textLabel?.text = post.title
        cell.detailTextLabel?.text = post.body

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "post-detail", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! PostDetailViewController
        destination.post = postFor(tableView.indexPathForSelectedRow!)
    }

    fileprivate func postFor(_ indexPath: IndexPath) -> Post {
        return posts[(indexPath as NSIndexPath).row]
    }

}

