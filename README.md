# Luncheon

[![CI Status](http://img.shields.io/travis/Dan2552/Luncheon.svg?style=flat)](https://travis-ci.org/Dan2552/Luncheon)
[![Version](https://img.shields.io/cocoapods/v/Luncheon.svg?style=flat)](http://cocoapods.org/pods/Luncheon)
[![License](https://img.shields.io/cocoapods/l/Luncheon.svg?style=flat)](http://cocoapods.org/pods/Luncheon)
[![Platform](https://img.shields.io/cocoapods/p/Luncheon.svg?style=flat)](http://cocoapods.org/pods/Luncheon)

## About

*Please note: Luncheon is in very early development. Some features mentioned in this README may not be finished but may be representational of the direction we want to head.*

*Also note: Due to protocol extensions, this project requires Swift 2.0 (and therefore Xcode 7)*

Luncheon is designed to have as minimal and simple setup as possible. With "convention over configuration" in mind we thought developing an app that communicates a REST API should be really simple. Other projects that try to tackle the same problems always end up with a lot of boiler-plate code or mapping relations.

At the moment, compatibility with a conventional Rails-served REST API is in mind, we hope to Luncheon will cover the majority of REST services, but *please keep in mind development is still in early days*. Feel free to send any pull requests our way!

Here are some of Luncheon's features:

- Complete resource mapping between local/remote models
	- Route mapping: A `Post` model matches up to the route `/posts`.
	- The server's `id` property is automatically mapped to `model.remote.id` locally.
	- Creating vs updating - depending on whether `model.remote.id` is present, calling `save()` will either create or update the resource (i.e. `POST /posts` or `PATCH /posts/42`).
	- Nested resource mapping.
	- When calling `save()` only the attributes that have been changed since being fetched will be sent up to the server.
	- Fields from JSON response are mapped directly to model properties. There is no manual JSON handling necessary (with the exception of a custom error handler).
	- Automatically maps `snake_case` properties to the Swift standard `camelCase`.
	- All network tasks are handled asyncronously

- Error handling
	- We sadly find a lot of developers actually completely overlook errors (especially when prototyping or MVPing), so we put in a no-setup default handler: By default, errors, from no-internet errors to validation errors with models, are alerted in an `UIAlertView`. Only the first error will be alerted as to avoid the end-user getting over-flooded.
	- Yet, still easily customisable (just set your own implemention to `Luncheon.Options.errorHandler`)
- Easily get model property values as a dictionary with `attributes()` and `attributesUnderscore()`

- Flexibility
  - Luncheon takes advantage of Swift 2.0 protocol extensions, meaning that your Luncheon models can subclass other libraries, meaning you can use the same objects with CoreData or other third party libraries.


## Usage

Configuration can be as simple as supplying a baseUrl:

```swift
Luncheon.Options.baseUrl = "http://jsonplaceholder.typicode.com"
```

Defining a model:

```swift
class Post: NSObject, Lunch {
    dynamic var title : String?

    required override init() {
      super.init()
    }
}
```

Grab and print out list of posts:

```swift
// GET /posts
Post.all { (posts: [Post] in
    for post in posts {
        println(post.title)
    }
}
```

Create a new post and print out the response resource's attributes:

```swift
let myPost = Post()
myPost.title = "Wow, Luncheon saves me so much time"

// POST /posts
myPost.save { post in
	println(post.attributes())
}
```

Grab an existing post and print its attributes:

```swift
// GET /posts/42
Post.find(42) { post in println(post.attributes()) }
```

Or some accociated comments on a post:

```swift
// GET /posts/42/comments
post.remote.accociated(Comment).all { (comments: [Comment]) in
    for comment in comments {
        println(comment.title)
    }
}
```

## Installation

Luncheon is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Luncheon", git: "https://github.com/Dan2552/Luncheon.git"
```

## Main Contributors

- [Daniel Green](https://github.com/Dan2552)
- [Tim Preuß](https://github.com/planerde)

## License

Luncheon is available under the MIT license. See the LICENSE file for more info.
