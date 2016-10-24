import Luncheon

class Post: NSObject, Lunch {
    dynamic var title: String?
    dynamic var body: String?
    dynamic var userId: NSNumber?
    dynamic var remoteId: NSNumber?

    required override init() {
        super.init()
    }
}
