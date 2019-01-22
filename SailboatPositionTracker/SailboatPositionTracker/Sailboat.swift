//
//  Sailboat.swift
//  SailboatPositionTracker
//
//  Created by Tom Frikker on 1/22/19.
//  Copyright © 2019 TuftsSP2019. All rights reserved.
//

import Foundation

class Sailboat {
    var id: String;
    var pos: Position;
    init() {
        self.id = "NewSailboat"
        self.pos = Position()
    }
    init(id: String, pos: Position) {
        self.id = id
        self.pos = pos
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
}
