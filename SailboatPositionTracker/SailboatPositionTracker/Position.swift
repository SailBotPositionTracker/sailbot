//
//  Position.swift
//  SailboatPositionTracker
//
//  Created by Tom Frikker on 1/22/19.
//  Copyright © 2019 TuftsSP2019. All rights reserved.
//

import Foundation

enum PositionError: Error {
    case InvalidStringFormat
}

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
    
    init (RTKLIBString: String) throws {
        let cols = RTKLIBString.components(separatedBy: " ")
        //check for standard RTKLIB format length
        if (cols.count != 15) {
            throw PositionError.InvalidStringFormat
        }
        self.GPST = Double(cols[1])!
        self.lat = Double(cols[2])!
        self.lon = Double(cols[3])!
        self.height = Double(cols[4])!
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
