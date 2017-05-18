import Foundation
import Vapor

enum EventStatus: String {
    case past
    case upcoming
}

final class Event {

    let id: String
    let name: String
    let rsvp_limit: Int?
    let status: EventStatus
    let time: Int
    let utc_offset: Int
    let waitlist_count: Int
    let yes_rsvp_count: Int
    // TODO: venue
    // TODO: group
    let link: String
    let description: String

    var utcDate: Date {
        let normalizedTime = TimeInterval(time / 1000)
        return Date(timeIntervalSince1970: normalizedTime)
    }
    
    func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "en-us")
        return dateFormatter.string(from: utcDate) 
    }

    init(
        id: String,
        name: String,
        rsvp_limit: Int?,
        status: EventStatus,
        time: Int,
        utc_offset: Int,
        waitlist_count: Int,
        yes_rsvp_count: Int,
        link: String,
        description: String
    ) {
        self.id = id
        self.name = name
        self.rsvp_limit = rsvp_limit
        self.status = status
        self.time = time
        self.utc_offset = utc_offset
        self.waitlist_count = waitlist_count
        self.yes_rsvp_count = yes_rsvp_count
        self.link = link
        self.description = description
    }

    convenience init? (json: JSON) {

        guard let id = json["id"]?.string else {
            print("Could not parse id from \(json)")
            return nil
        }
        guard let name = json["name"]?.string else {
            print("Could not parse name from \(json)")
            return nil
        }
        let rsvp_limit = json["rsvp_limit"]?.int
        guard let time = json["time"]?.int else {
            print("Could not parse time from \(json)")
            return nil
        }
        guard let utc_offset = json["utc_offset"]?.int else {
            print("Could not parse utc_offset from \(json)")
            return nil
        }
        guard let waitlist_count = json["waitlist_count"]?.int else {
            print("Could not parse waitlist_count from \(json)")
            return nil
        }
        guard let yes_rsvp_count = json["yes_rsvp_count"]?.int else {
            print("Could not parse yes_rsvp_count from \(json)")
            return nil
        }
        guard let link = json["link"]?.string else {
            print("Could not parse link from \(json)")
            return nil
        }
        guard let description = json["description"]?.string else {
            print("Could not parse description from \(json)")
            return nil
        }
        guard let rawStatus = json["status"]?.string, let status = EventStatus(rawValue: rawStatus) else {
            print("Could not parse status from \(json)")
            return nil
        }


        self.init(
            id: id,
            name: name,
            rsvp_limit: rsvp_limit,
            status: status,
            time: time,
            utc_offset: utc_offset,
            waitlist_count: waitlist_count,
            yes_rsvp_count: yes_rsvp_count,
            link: link,
            description: description
        )
    }
}

extension Event: NodeRepresentable {
    func makeNode(context: Context) throws -> Node {
        let node = try Node(node: [
            "id": Node(id),
            "name": Node(name),
            "rsvp_limit": rsvp_limit == nil ? EmptyNode : Node(rsvp_limit!),
            "status": Node(status.rawValue),
            "time": Node(time),
            "utc_offset": Node(utc_offset),
            "waitlist_count": Node(waitlist_count),
            "yes_rsvp_count": Node(yes_rsvp_count),
            "link": Node(link),
            "description": Node(description),
            "formattedDate": Node(formattedDate())
        ])
        return node
    }
}
