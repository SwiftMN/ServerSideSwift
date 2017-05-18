build-lists: true
theme: Letters from Sweden, 4

# [fit] Server-side Swift

# [fit] Swift MN

^ Thank When I Work

^ Using Swift outside of Xcode - Adam Mika

----
[.build-lists: false]

### Frameworks available [^1]

* [Perfect](https://github.com/perfectlySoft/Perfect) ⭐ 11,427  
* [Vapor](https://github.com/vapor/Vapor) ⭐ 9,466
* [Kitura](https://github.com/ibm-swift/kitura) ⭐ 5,682
* [Zewo](https://github.com/zewo/Zewo) ⭐ 1651

[^1]: Github Stars as of 2017/5/15

^ Vapor catching up

----
[.build-lists: false]
### Why I chose Vapor:

* I read through the docs for both
* I joined both Slack groups
* Vapor felt more interesting to me ¯\\\_(ツ)_/¯
* Interesting article comparing the communities of Perfect and Vapor
    * [https://www.sitepoint.com/server-side-swift-comparing-vapor-perfect](https://www.sitepoint.com/server-side-swift-comparing-vapor-perfect)

^ 

^ 

^ 

^ plan to build with Perfect

----

# [fit] Getting Started With Vapor

----
[.build-lists: false]
### Install Vapor (macOS)
 
* Add Homebrew Tap

        brew tap vapor/homebrew-tap
        brew update

* Install Vapor

        brew install vapor

* Verify Installation
        
        vapor --help

----
[.build-lists: false]
### Starting A New Project

* Create the App

        vapor new SwiftMN
        cd SwiftMN

* Build the app

        vapor build

* Run the app

        .build/debug/App

---- 

Open a browser and navigate to `localhost:8080`

![inline fit](https://d3vv6lp55qjaqc.cloudfront.net/items/401z1L3S0R072s2V0C2B/Screen%20Shot%202017-04-21%20at%2011.28.45%20AM.png)


----
### Debugging

Make sure you change your scheme to `App`  

Xcode

![inline fit left](https://d3vv6lp55qjaqc.cloudfront.net/items/1B1a1C2b0E1v0C2E222T/Screen%20Shot%202017-04-21%20at%2011.25.18%20AM.png)

AppCode

![inline fit left](https://d3vv6lp55qjaqc.cloudfront.net/items/3A1d3X3u3R3t21283E2Z/Screen%20Shot%202017-04-21%20at%2011.23.16%20AM.png)

^  play button in Xcode
bug button in AppCode

----
[.build-lists: false]
### A note about the docs:  

They're all over the place and incomplete

* [~~docs.vapor.codes~~](http://docs.vapor.codes)
* [~~beta.docs.vapor.codes~~](http://beta.docs.vapor.codes)
* [docs.vapor.codes/2.0/](http://docs.vapor.codes/2.0/)
* [api.vapor.codes](http://api.vapor.codes/)
* read the code [github.com.vapor/vapor](https://github.com/vapor/vapor)
* ask on Slack

^ read the docs, then code, then ask on Slack
^ active on Slack

----

# [fit] Building The App

----
### main.swift

    Droplet()

The `Droplet` is a service container that gives you access to many of Vapor's facilities. It is responsible for registering routes, starting the server, appending middleware, and more.

^ The Droplet is everything. It's basically your entire app.
It handles:
routing, 
caching, 
environment variables...
pretty much anything your app needs to do is done with the droplet.

----
### main.swift

    import Vapor
    let drop = try Droplet()
    try drop.run()

^ This is all it takes to start your Vapor app.

^ 

^ 

^ 👀 Routing

----
### Simple routes

    import Vapor
    let drop = try Droplet()

    drop.get { req in
        return try drop.view.make("welcome", [
            "message": drop.localization[req.lang, "welcome", "title"]
        ])
    }

    try drop.run()

^ added a simple route

^ 

^ 

^ 👀 line by line

----
### Simple routes

        drop.get { req in

All GET requests to "/" will execute the block.

^ exposing route to "/" for GET

^ 

^ `put`, `post`, `delete`, etc.

----
### Simple routes

        drop.get { req in
            return try drop.view.make("welcome", [

The Droplet will try to build and return `welcome.leaf`

^ `drop.view.make` builds a view

^ first parameter: `welcome.leaf`

^ `leaf` == templating engine

^ more later

^ 👀 view.make

----
### Simple routes

    public func make(_ path: String) throws -> View {
        return try make(path, Node.null)
    }

    public func make(_ path: String, _ context: NodeRepresentable) throws -> View {
        return try make(path, try context.makeNode())
    }

    public func make(_ path: String, _ context: [String: NodeRepresentable]) throws -> View {
        return try make(path, try context.makeNode())
    }

^ This is what `view.make` actually looks like

^ NodeRepresentable, helps with behind the scenes conversions

^ almost everything is a Node

----
### Simple routes

        drop.get { req in
            return try drop.view.make("welcome", [
                "message": drop.localization[req.lang, "welcome", "title"]
            ])
        }

We pass a localized message in our context object

^ 

^ So what about URIs other than `/`

____
### Simple routes
    
The verbs are Variadic functions

        drop.get("about") { req in
            // handle GET requests to "/about"
        }
                
        drop.post("some", "other", "place") { req in
            // handle POST requests to /some/other/place
        }
 
        drop.get("anything", "*") { req in
            // wildcards match anything after /anything
        }

^ break 'em down

----
### Simple routes

Path Parameters

        drop.put("events", ":id") { req in
            guard let id = req.parameters["id"]?.string else {
                throw Abort.badRequest
            }
            // Update the event with the given id
        }

^ specify path paramter

^ typical use case: `id`

^ 

^ 

^ 👀 But they take it even further than that

----
### Simple routes

TypeSafe Path Parameters

        drop.put("events", Int.self) { req, id in
            // Update the event with the given id
        }

^ expect int,
second argument is id.
else throw

        drop.put("events", Event.self) { req, event in
            // Update the given event
        }

^

^ conform to Model protocol

^ next version adds `Parameterizable` protocol

^ Model is tightly coupled to their database protocols

----

# [fit] CONTROLLERS

^ defining simple routes in main.swift is fine, but that file will get out of control fast

^ 

^ 

^ 👀 So let's start moving things into controllers

----
### Routing groups

        drop.group("events") { route in
            let eventController = MeetupController(drop: drop)
            route.get(handler: eventController.listEvents)
            route.get(":id", handler: eventController.getEvent)
        }

All requests to /events will execute this closure

^ So instead of defining each request 1 at a time, we can `group` our endpoints together

^ 

^ 

^ 👀 line by line

----
### Routing groups

        drop.group("events") { route in

All requests to /events should execute this closure

^ all requests to the "/events" endpoint should execute this closure,
GET, PUT, POST, DELETE
/events
/events/:id

----
### Routing groups

        drop.group("events") { route in
            let eventController = MeetupController(drop: drop)

Create a Controller to handle each request

^ `MeetupController` instance to handle each request

----
### Routing groups

        drop.group("events") { route in
            let eventController = MeetupController(drop: drop)
            route.get(handler: eventController.listEvents)
            route.get(":id", handler: eventController.getEvent)
        }

GET requests to "/events" will hit the `listEvents` function

GET requests to "/events/:id" will hit the `getEvent` function

^ `route.get` is similar to `drop.get`, but with a `handler` parameter instead of a closure to execute

^ 

^ 

^ 👀 `listEvents`

----
MeetupController

    func listEvents(_ request: Request) throws -> ResponseRepresentable {
        let events: [Event] = try fetchEvents(request)
        
        var upcoming: [Event] = []
        var past: [Event] = []
        
        events.forEach {
            switch $0.status {
                case .upcoming: upcoming.append($0)
                case .past: past.append($0)
            }
        }
        
        return try drop.view.make("listEvents", [
            "allEvents": events.makeNode(),
            "upcomingEvents": upcoming.makeNode(),
            "pastEvents": past.makeNode()
        ])
    }

^ First line: fetch from meetup API

^ 

^ 

^ 👀 `fetchEvents`

----
MeetupController
    
    private func fetchEvents(_ request: Request) throws -> [Event] {
        let path = "https://api.meetup.com/SwiftMN/events"
        let headers: [HeaderKey: String] = [
            HeaderKey.contentType: "application/json" 
        ]
        let query: [String: CustomStringConvertible] = [
            "status": "upcoming,past", 
            "desc": true
        ]        

        // synchronous request to the meetup API
        let eventsResponse = try drop.client.get(path, headers: headers, query: query)

        ... // a lot of parsing and data conversion happens

        return events
    }

^ define our path, headers, and query

^ `drop.client.get` is synchronous

^ async???

^ 

^ 

^ 👀 back to `listEvents`

----
MeetupController

    func listEvents(_ request: Request) throws -> ResponseRepresentable {
        let events: [Event] = try fetchEvents(request)
        
        var upcoming: [Event] = []
        var past: [Event] = []
        
        events.forEach {
            switch $0.status {
                case .upcoming: upcoming.append($0)
                case .past: past.append($0)
            }
        }
        
        return try drop.view.make("listEvents", [
            "allEvents": events.makeNode(),
            "upcomingEvents": upcoming.makeNode(),
            "pastEvents": past.makeNode()
        ])
    }

^ fetch events,
split into past and upcoming

^ build our view

^ 

^ 

^ 👀 which brings us to

----

# [fit] Leaf

^ `leaf` is Vapor's templating engine

^ 

^ 

^ 👀 And you define a leaf like this:

----
base.leaf  

    <!DOCTYPE html>
    <html>
        <head>
            <link rel="stylesheet" href="/styles/app.css">
            #import("head")
            #embed("bootstrap")
        </head>
        <body>
            #import("body")
        </body>
    </html>

^ basic HTML document

^ `#imports` the `head` and `body` from whatever `#extends` this `base.leaf`

^ 

^ 

^ 👀 

----
listEvents.leaf

    #extend("base")

    #export("head") {
        <title>SwiftMN Events</title>
    }

    #export("body") {
        ...
    }

----
Inside our `#export("body")` { ... }

    <div class=row>
        #loop(upcomingEvents, "event") {
            <div class="col-xs-6 col-lg-2">
                #(event.formattedDate)
            </div>
            <div class="col-xs-6 col-lg-10">
                <a href="/events/#(event.id)">#(event.name)</a></li>
            </div>
        }
    </div>

^ twitter bootstrap here

^ 

^ 

^ 👀 take that away

----
`#loop`

        #loop(upcomingEvents, "event") {
            ...
        }

`#loop` iterates over the `upcomingEvents` from our context object and provides us with a variable named `event`

----
MeetupController.listEvents

A reminder of where `upcomingEvents` came from

        return try drop.view.make("listEvents", [
            "allEvents": events.makeNode(),
            "upcomingEvents": upcoming.makeNode(),
            "pastEvents": past.makeNode()
        ])

----
`#(variable)`

        #(event.formattedDate)

Display the `formattedDate` variable on our event

        <a href="/events/#(event.id)">#(event.name)</a></li>

Build an achor tag using `event.id` in the url and `event.name` as the link text

^ 

^ 

^ 👀 put it all back together

----
Inside our `#export("body")` { ... }

    <div class=row>
        #loop(upcomingEvents, "event") {
            <div class="col-xs-6 col-lg-2">
                #(event.formattedDate)
            </div>
            <div class="col-xs-6 col-lg-10">
                <a href="/events/#(event.id)">#(event.name)</a></li>
            </div>
        }
    </div>

^ So we have a `div` defining our row.

^ any number events with a date and a url to the event page

^ 

^ 

^ 👀 

----

# [fit] [vapor.swift.mn](http://vapor.swift.mn)

----
[.build-lists: false]
### Built-in tags

* build on top of an existing leaf

        #extend("base")

* import code from an extended leaf

        #import("template")

* export code to the leaf that you've extended

        #export("template") { <a href="#()"></a> }

* embed another document

        #embed("commonCSS")

----
### Built-in tags

* variables
    
        #(event.name)

* literal "#" character

        #()

* equality checking

        #equal(thisVar, thatVar) {  
            thisVar and thatVar are equal 👏 
        }

----
### Built-in tags

* if / else if / else

        #if(entering) {
            Hello, there!
        } ##if(leaving) {
            Goodbye!
        } ##else() {
            I've been here the whole time.
        }

----
### Built-in tags

* iterate over an array

        #loop(friends, "friend") { <li>#(friend.name)</li> }

* grab a single item out of an array using it's index

        #index(events, 0)

* grab a single item out of a Dictionary

        #index(friends, "best")

----
### Built-in tags

* render as html/css/js instead of as a leaf document

        #raw() { 
            <a href="#raw">Anything goes!@#$%^&*</a> 
        }

* render an html string stored in a variable

        #raw(event.description)

^ Be careful rendering html from an API

^

^ Luckily, I write these descriptions so I'm not too worried about blindly rendering them.

----
### Custom tags

    class Index: BasicTag {
    let name = "index"

    func run(arguments: [Argument]) throws -> Node? {
        guard
            arguments.count == 2,
            let array = arguments[0].value?.nodeArray,
            let index = arguments[1].value?.int,
            index < array.count
        else { return nil }
            return array[index]
        }
    }

^ actual code for `#index`

^ To build your own, just conform to the `BasicTag` protocol

----
main.swift

After conforming to the `BasicTag` protocol, register your tag in main.swift

        if let leaf = drop.view as? LeafRenderer {
            leaf.stem.register(Index())
        }

^

^ 

^ 

^

^ 👀  back to handling requests

----

# [fit] Middleware

^ alter the request
alter the response
security
early exit
request logging

----
Middleware

    public protocol Middleware {
        func respond(to request: Request, chainingTo next: Responder) throws -> Response
    }

^ key: chaining

----
AuthMiddleware

    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        guard let bearer = request.auth.header?.bearer?.string else {
            throw Abort.custom(status: .unauthorized, message: "Not Authorized")
        }

        // throws if not authenticated
        let token = try validateToken(bearer)
        
        request.storage["token"] = token

        return try next.respond(to: request)
    }

^ request.storage

----


    extension Request {
        func token() throws -> AuthToken {
            guard let token = request.storage["token"] as? AuthToken else {
                throw notAuthorizedError
            }
            return token
        }
    }

    // anywhere after AuthMiddleware
    let token = try request.token()



----
main.swift

    let secure = drop.grouped(AuthMiddleware())
    
    secure.group("user") { route in
        // everything here is secured
    }

----
EtagMiddleware

    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        if checkEtag(request.headers[.ifNoneMatch]) {
            return Response(status: .notModified)
        }
        return try next.respond(to: request)
    }

^ custom convenience initializer

----
main.swift

    let secure = drop.grouped(AuthMiddleware(), EtagMiddleware())
    
    secure.group("user") { route in
        // everything here is secured
    }

----
# [fit] SHIP IT

----
### Install Vapor on your server

[docs.vapor.codes v1.5](https://docs.vapor.codes/1.5/getting-started/install-swift-3-ubuntu.html)

[docs.vapor.codes v2.0](https://docs.vapor.codes/2.0/getting-started/install-on-ubuntu/)

^ We're going to use the 2.0 instructions because they're easier

----
### Install Vapor on your server

* You'll need curl        
  
        apt install curl

* Easily add Vapor's APT repo with this handy script

        eval "$(curl -sL https://apt.vapor.sh)"

* Install Swift and Vapor

        sudo apt-get install swift vapor

* Double check the installation was successful

        eval "$(curl -sL check2.vapor.sh)"

----
### Build

* clone the repo

        cd /home/ubuntu
        git clone https://github.com/vlaminck/SwiftMN.git
        cd SwiftMN

* Update Swift Packages

        swift package update

* build for release

        vapor build --release

----
[.build-lists: false]
### Verify

* Run your app manually to verify that it works

        .build/release/App --env=production

---- 
[.build-lists: false]
### Verify

* Open a browser and navigate to your server 
    
![inline fit](https://d3vv6lp55qjaqc.cloudfront.net/items/0a0L1R2Y180q1o2N402C/Screen%20Shot%202017-05-16%20at%205.35.39%20PM.png)

----
Your app as a system service

        sudo mv etc/app.service /lib/systemd/system
        sudo chown root:root /lib/systemd/system/app.service
        sudo systemctl daemon-reload
        systemctl status app

----
Auto reloading

        sudo systemctl enable app
        sudo systemctl restart app

----
Auto Deployments

        // TODO:

^ I started looking Jenkins and Docker, but I ran out of time

^ Another interesting option is Flock

* 3rd party options
    * [Flock](https://github.com/jakeheis/Flock)

----
[.build-lists: false]
### Quick recap

* Available frameworks
* Getting started with vapor
* Routing
* Controllers / meetup API
* Leaf (templating engine)
* vapor.swift.mn
* Manual Deployments

----
[.build-lists: false]
### Next Steps

* More meetup API integration
* talk suggestions
    * 👍
* Anything you want
    * [github.com/SwiftMN](https://github.com/SwiftMN)

^ do what you think is interesting
^ Vapor, 
Perfect, 
RxSwift 👍

----
### Next Month

WWDC Micro Talks

^ anything you find interesting

----

# [fit] [slack.swift.mn](slack.swift.mn)

^ #talks, #wwdc
