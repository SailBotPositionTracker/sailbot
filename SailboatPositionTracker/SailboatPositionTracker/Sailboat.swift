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
    var pos: Position
    var status: raceStatus
    init() {
        self.id = "NewSailboat"
        self.pos = Position()
        self.status = raceStatus.notstarted
    }
    init(id: String) {
        self.id = id
        self.pos = Position()
        self.status = raceStatus.notstarted
    }
    init(id: String, pos: Position) {
        self.id = id
        self.pos = pos
        self.status = raceStatus.notstarted
    }
    
    func getId() -> String {
        return self.id
    }
    
    func setId(id: String) {
        self.id = id
    }
    
    func getPosition() -> Position {
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
