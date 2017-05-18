import Vapor

let drop = Droplet()

drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

drop.group("events") { route in
    let eventController = MeetupController(drop: drop)
    route.get(handler: eventController.listEvents)
    route.get(":id", handler: eventController.getEvent)
}

drop.get("about") { request in
    return try drop.view.make("about")
}

drop.run()
