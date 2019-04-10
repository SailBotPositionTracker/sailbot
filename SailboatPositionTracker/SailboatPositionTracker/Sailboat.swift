//
//  Sailboat.swift
//  SailboatPositionTracker
//
//  Created by Tom Frikker on 1/22/19.
//  Copyright © 2019 TuftsSP2019. All rights reserved.
//

import Foundation

class Sailboat {
    enum raceStatus {
        case notstarted
        case started
        case over
        case cleared
    }
    var id: String
    var fleet: String
    var pos: Position?
    var status: raceStatus
    init(id: String = "NewSailboat", fleet: String = "", pos: Position? = nil, status: raceStatus = raceStatus.notstarted) {
        self.id = id
        self.fleet = fleet
        self.pos = pos
        self.status = status
    }
    
    func getId() -> String {
        return self.id
    }
    
    func setId(id: String) {
        self.id = id
    }
    
    func getFleet() -> String {
        return self.fleet
    }
    
    func setFleet(fleet: String) {
        self.fleet = fleet
    }
    
    func getPosition() -> Position? {
        return self.pos
    }
    
    func setPosition(pos: Position) {
        self.pos = pos
    }
    
    func getStatus() -> raceStatus {
        return self.status
    }
    
    func setStatus(status: raceStatus) {
        self.status = status
    }
}
