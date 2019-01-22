//
//  ViewController.swift
//  SailboatPositionTracker
//
//  Created by Tom Frikker on 1/9/19.
//  Copyright © 2019 TuftsSP2019. All rights reserved.
//

import UIKit
import SwiftSocket

class ViewController: UIViewController {
    
    @IBOutlet weak var timerLabel: UILabel!
    
    
    var timerLength = 60
    var seconds = 0
    var timer = Timer()
    var isTimerRunning = false
    
    var resumeTapped = false
    
    //map from TCP connection identifier to Sailboat object
    var fleetMap = [String: Sailboat]()
    
    /*
    d = (lat_sailboat - lat_commboat)(lon_pin - lon_commboat) - (lon_sailboat - lon_commboat)(lat_pin - lat_commboat) / sqrt((lat_pin - lat_commboat)^2 + (lon_pin - lon_commboat)^2)
    */
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        if isTimerRunning == false {
            runTimer()
        }
    }
    
    func runTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        if self.resumeTapped == false {
            timer.invalidate()
            self.resumeTapped = true
        } else {
            runTimer()
            self.resumeTapped = false
        }
    }
    
    @IBAction func resetButtonTapped(_ sender: UIButton) {
        timer.invalidate()
        seconds = timerLength
        timerLabel.text = "\(seconds)"
        isTimerRunning = false
    }
    
    @objc func updateTimer() {
        if seconds < 1 {
            timer.invalidate()
            //Send alert to indicate "time's up!"
        } else {
            seconds -= 1
            timerLabel.text = timeString(time: TimeInterval(seconds))
        }
    }
    
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    // Do any additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //init the timer seconds
        seconds = timerLength
        
        //Start the TCP server when the view loads
        func echoService(client: TCPClient) {
            var clientIdentifier = client.address + String(client.port)
            print("New connection from:\(client.address)[\(client.port)]")
            //stream in the position data
            while true{
                //TODO: find the exact length to read
                var d = client.read(10)
                print("     \(client.address)[\(client.port)]: \(d)")
                //TODO: convert this byte array to a string
                /*
                let test = "A test output position string from RTKLIB"
                let curpos = Position(test)
                fleetMap[clientIdentifier].setPosition(curpos)
                */
            }
            client.close()
        }
        
        func testServer() {
            let server = TCPServer(address: "127.0.0.1", port: 8080)
            switch server.listen() {
            case .success:
                while true {
                    if var client = server.accept() {
                        //TODO: should probably use MAC address instead
                        var clientIdentifier = client.address + String(client.port)
                        fleetMap[clientIdentifier] = Sailboat()
                        echoService(client: client)
                    } else {
                        print("accept error")
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
        testServer()
    }


}

