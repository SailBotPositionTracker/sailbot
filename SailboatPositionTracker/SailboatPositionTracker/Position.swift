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
    var n: Double;
    var e: Double;
    var u: Double;
    init() {
        GPST = 0
        n = 0
        e = 0
        u = 0
    }
    init (GPST: Double, n: Double, e: Double, u: Double) {
        self.GPST = GPST
        self.n = n
        self.e = e
        self.u = u
    }
    
    init (RTKLIBString: String) throws {
        let cols = RTKLIBString.components(separatedBy: " ")
        //check for standard RTKLIB format length
        if (cols.count != 15) {
            throw PositionError.InvalidStringFormat
        }
        self.GPST = Double(cols[1])!
        self.n = Double(cols[2])!
        self.e = Double(cols[3])!
        self.u = Double(cols[4])!
    }
    
    func getGPST() -> Double {
        return self.GPST
    }
    
    func setGPST(GPST: Double) {
        self.GPST = GPST
    }
    
    func getN() -> Double {
        return self.n
    }
    
    func setN(n: Double) {
        self.n = n
    }
    
    func getE() -> Double {
        return self.e
    }
    
    func setE(e: Double) {
        self.e = e
    }
    
    func getU() -> Double {
        return self.u
    }
    
    func setU(u: Double) {
        self.u = u
    }
}
