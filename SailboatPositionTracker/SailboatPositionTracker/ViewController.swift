//
//  ViewController.swift
//  SailboatPositionTracker
//
//  Created by Tom Frikker on 1/9/19.
//  Copyright © 2019 TuftsSP2019. All rights reserved.
//

import UIKit
import SwiftSocket

class ViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    private var data: [String] = []
    
    var timerLength: Int = 300
    var seconds: Int = 0
    var timer: Timer = Timer()
    var isTimerRunning: Bool = false
    
    @IBOutlet weak var timerLabel: UILabel!
    
    //map from TCP connection identifier to Sailboat object
    var fleetMap = [String: Sailboat]()
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")! //1.
        
        let text = data[indexPath.row] //2.
        
        cell.textLabel?.text = text //3.
        
        return cell //4.
    }
    
    
    
    
    
    

    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        print("Start button tapped")
        if !isTimerRunning {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            isTimerRunning = true;
        } else {
            timer.invalidate()
            isTimerRunning = false;
        }
    }
    
    @IBAction func resetButtonTapped(_ sender: UIButton) {
        timer.invalidate()
        seconds = timerLength
        isTimerRunning = false
        timerLabel.text = timeString(time: TimeInterval(seconds))
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
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%01i:%02i", minutes, seconds)
    }
    
    func calcDistanceToLine(sailboat: Sailboat) -> Double {
        /*
        let pos_sail = sailboat.getPosition()
        let lat_sail = pos_sail.getLat()
        let lon_sail = pos_sail.getLon()
        //TODO: reference the boat and pin trackers in a more scalable and concrete way
        let pos_comm = self.fleetMap["192.168.4.1:5000"]!.getPosition()
        let lat_comm = pos_comm.getLat()
        let lon_comm = pos_comm.getLon()
        let pos_pin = self.fleetMap["192.168.4.2:5000"]!.getPosition()
        let lat_pin = pos_pin.getLat()
        let lon_pin = pos_pin.getLon()
        let num = ((lat_sail - lat_comm) * (lon_pin - lon_comm) - (lon_sail - lon_comm) * (lat_pin - lat_comm))
        let den = sqrt(pow((lat_pin - lat_comm), 2) + pow((lon_pin - lon_comm), 2))
        return num / den
        */
        
        //if relative to the committee boat
        let pos_sail = sailboat.getPosition()
        let n_sail = pos_sail.getLat()
        let e_sail = pos_sail.getLon()
        let pos_pin = self.fleetMap["192.168.4.2:5000"]!.getPosition()
        let n_pin = pos_pin.getLat()
        let e_pin = pos_pin.getLon()
        return ((n_sail * e_pin) - (e_sail * n_pin)) / sqrt(pow(n_pin, 2) + pow(e_pin, 2))
    }
    
    // Do any additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 0...1000 {
            data.append("\(i)")
        }
        tableView.dataSource = self
        //Initialize the timer to "full"
        seconds = timerLength
        
        //TODO: hard-coded pin and comm boat for testing
        self.fleetMap["192.168.4.2:5000"] = Sailboat(id: "pin", pos: Position(GPST: 1.0, lat: 5.0, lon: 5.0, height: 0.0))
        //init the timer label
        timerLabel.text = timeString(time: TimeInterval(seconds))
        
        //Start the TCP server when the view loads on a separate high time precision thread
        DispatchQueue.global(qos: .userInteractive).async {
            func echoService(client: TCPClient) {
                let clientIdentifier = client.address + ":" + String(client.port)
                print("New connection from:\(client.address)[\(client.port)]")
                while true {
                    //TODO: find the exact length to read
                    let d = client.read(71)
                    if let unwrapped = d {
                        if let string_msg = String(bytes: unwrapped, encoding: .utf8) {
                            print("     \(client.address)[\(client.port)]: \(string_msg)")
                            do {
                                let curpos = try Position(RTKLIBString: string_msg)
                                self.fleetMap[clientIdentifier]!.setPosition(pos: curpos)
                                print("DISTANCE TO LINE " + String(clientIdentifier) + ": " + String(self.calcDistanceToLine(sailboat: self.fleetMap[clientIdentifier]!)))
                            } catch PositionError.InvalidStringFormat {
                                print("Invalid position string from RTKLIB")
                            } catch {
                                print("Unexpected error: \(error).")
                            }
                        } else {
                            print("Non-UTF-8 sequence from RTKLIB")
                        }
                    }
                }
                client.close()
            }
            
            func testServer() {
                let server = TCPServer(address: "127.0.0.1", port: 8080)
                switch server.listen() {
                case .success:
                    while true {
                        if let client = server.accept() {
                            //TODO: should probably use MAC address instead
                            let clientIdentifier = client.address + ":" + String(client.port)
                            self.fleetMap[clientIdentifier] = Sailboat()
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
}

