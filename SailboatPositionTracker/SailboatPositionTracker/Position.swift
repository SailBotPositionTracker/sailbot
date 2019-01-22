//
//  Position.swift
//  SailboatPositionTracker
//
//  Created by Tom Frikker on 1/22/19.
//  Copyright © 2019 TuftsSP2019. All rights reserved.
//

import Foundation

class Position {
    var GPST: Double;
    var lat: Double;
    var lon: Double;
    var height: Double;
    init() {
        GPST = 0
        lat = 0
        lon = 0
        height = 0
    }
    init (GPST: Double, lat: Double, lon: Double, height: Double) {
        self.GPST = GPST
        self.lat = lat
        self.lon = lon
        self.height = height
    }
    init (RTKLIBString: String) {
        let cols = RTKLIBString.components(separatedBy: " ")
        self.GPST = cols[1]
        self.lat = cols[2]
        self.lon = cols[3]
        self.height = cols[4]
    }
    
    func getGPST() -> Double {
        return self.GPST
    }
    
    func setGPST(GPST: Double) {
        self.GPST = GPST
    }
    
    func getLat() -> Double {
        return self.lat
    }
    
    func setLat(lat: Double) {
        self.lat = lat
    }
    
    func getLon() -> Double {
        return self.lon
    }
    
    func setLon(lon: Double) {
        self.lon = lon
    }
    
    func getHeight() -> Double {
        return self.height
    }
    
    func setHeight(height: Double) {
        self.height = height
    }
}
