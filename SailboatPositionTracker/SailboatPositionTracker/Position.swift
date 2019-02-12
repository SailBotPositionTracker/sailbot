//
//  Position.swift
//  SailboatPositionTracker
//
//  Created by Tom Frikker on 1/22/19.
//  Copyright © 2019 TuftsSP2019. All rights reserved.
//

import Foundation

extension String {
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }
}

enum PositionError: Error {
    case InvalidStringFormat
}

class Position {
    var GPST: Double;
    var n: Double;
    var e: Double;
    init() {
        GPST = 0
        n = 0
        e = 0
    }
    init (GPST: Double, n: Double, e: Double, u: Double) {
        self.GPST = GPST
        self.n = n
        self.e = e
    }
    
    init (RTKLIBString: String) throws {
        var input = RTKLIBString
        input = input.removingWhitespaces()
        //print("INPUT PARSED:" + input)
        let cols = RTKLIBString.components(separatedBy: ",")
        //check for standard RTKLIB format length
        if (cols.count != 15) {
            throw PositionError.InvalidStringFormat
        }
        self.GPST = Double(cols[1].trimmingCharacters(in: .whitespaces))!
        self.n = Double(cols[2].trimmingCharacters(in: .whitespaces))!
        self.e = Double(cols[3].trimmingCharacters(in: .whitespaces))!
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
}
