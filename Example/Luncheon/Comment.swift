import Luncheon

class Comment: NSObject, Lunch {
    dynamic var email: String?
    dynamic var body: String?

    required override init() {
        super.init()
    }
}
