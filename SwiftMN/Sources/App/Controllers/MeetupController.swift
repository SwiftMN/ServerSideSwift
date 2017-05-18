import Vapor
import HTTP

final class MeetupController {

    let drop: Droplet

    init(drop: Droplet) {
        self.drop = drop
    }

    private func fetchEvents(_ request: Request) throws -> [Event] {
        if let rawStatus = request.data["status"]?.string, let status = EventStatus(rawValue: rawStatus) {
            print("do something with: \(status)")
        }

        let headers: [HeaderKey: String] = [
            HeaderKey.contentType: "application/json" 
        ]

        let query: [String: CustomStringConvertible] = [
            "status": "upcoming,past",
            "desc": true
        ]

        let eventsResponse = try drop.client.get("https://api.meetup.com/SwiftMN/events", headers: headers, query: query)

        guard let bytes = eventsResponse.body.bytes else {
            throw Abort.custom(status: .unauthorized, message: "No Shard response body")
        }
        let json = try JSON(bytes: bytes)
        
        
        guard let eventsJSON: [JSON] = json.array as? [JSON] else {
            throw Abort.custom(status: .unauthorized, message: "unable to parse events")
        }
        
        let events: [Event] = try eventsJSON.map { 
            guard let eventJson: JSON = $0 as? JSON, let event = Event(json: eventJson) else {
                throw Abort.custom(status: .unauthorized, message: "unable to parse event")
            }
            return event
        }

        return events
    }

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
    
    func getEvent(_ request: Request) throws -> ResponseRepresentable {
        
        guard let id = request.parameters["id"]?.string else {
            throw Abort.badRequest
        }
        
        let events = try fetchEvents(request)
        let firstEvent = events.first { $0.id == id }
        guard let event = firstEvent else {
            throw Abort.badRequest
        }
        return try drop.view.make("showEvent", [
            "event": event.makeNode()
        ])
    }
    
}