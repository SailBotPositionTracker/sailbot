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
    private var tableMap = [String: String]()
    
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
        let data = Array(tableMap.values)
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = Array(tableMap.values)
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")!
        cell.textLabel?.text = data[indexPath.row]
        return cell
    }
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        if !isTimerRunning {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        } else {
            timer.invalidate()
        }
        isTimerRunning = !isTimerRunning
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
        } else {
            seconds -= 1
            timerLabel.text = timeString(time: TimeInterval(seconds))
        }
    }
    
    func timeString(time:TimeInterval) -> String {
        let min = Int(time) / 60 % 60
        let sec = Int(time) % 60
        return String(format:"%01i:%02i", min, sec)
    }
    
    func calcDistanceToLine(sailboat: Sailboat) -> Double {
        //TODO: reference the boat and pin trackers in a more scalable and concrete way
        //using positions of both pin and committee boat
        /*
        let pos_sail = sailboat.getPosition()
        let n_sail = pos_sail.getN()
        let e_sail = pos_sail.getE()
        let pos_comm = self.fleetMap["192.168.4.1:5000"]!.getPosition()
        let n_comm = pos_comm.getN()
        let e_comm = pos_comm.getE()
        let pos_pin = self.fleetMap["192.168.4.2:5000"]!.getPosition()
        let n_pin = pos_pin.getN()
        let e_pin = pos_pin.getE()
        let num = ((n_sail - n_comm) * (e_pin - e_comm) - (e_sail - e_comm) * (n_pin - n_comm))
        let den = sqrt(pow((n_pin - n_comm), 2) + pow((e_pin - e_comm), 2))
        return num / den
        */
        
        //if relative to the committee boat (assuming base tracker is at (0, 0) at line boat end)
        let pos_sail = sailboat.getPosition()
        let n_sail = pos_sail.getN()
        let e_sail = pos_sail.getE()
        let pos_pin = self.fleetMap["192.168.4.2:5000"]!.getPosition()
        let n_pin = pos_pin.getN()
        let e_pin = pos_pin.getE()
        return ((n_sail * e_pin) - (e_sail * n_pin)) / sqrt(pow(n_pin, 2) + pow(e_pin, 2))
    }
    
    func gatherPositions(client: TCPClient, clientId: String) {
        print("New connection from:\(client.address)[\(client.port)]")
        while true {
            //TODO: find the exact length to read
            let d = client.read(71)
            if let unwrapped = d {
                if let string_msg = String(bytes: unwrapped, encoding: .utf8) {
                    //print("     \(client.address)[\(client.port)]: \(string_msg)")
                    do {
                        let curpos = try Position(RTKLIBString: string_msg)
                        self.fleetMap[clientId]!.setPosition(pos: curpos)
                        let dist_to_line = self.calcDistanceToLine(sailboat: self.fleetMap[clientId]!)
                        //define the text shown in the table
                        self.tableMap[clientId] = String(clientId) + ": " + (NSString(format: "%.2f", dist_to_line) as String) as String + "m"
                        //reload table data from main thread
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
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
    
    func runTCPServer() {
        let server = TCPServer(address: "127.0.0.1", port: 8080)
        switch server.listen() {
        case .success:
            while true {
                if let client = server.accept() {
                    //TODO: should probably use MAC address instead
                    let clientId = client.address + ":" + String(client.port)
                    self.fleetMap[clientId] = Sailboat()
                    gatherPositions(client: client, clientId: clientId)
                } else {
                    print("TCP accept error")
                }
            }
        case .failure(let error):
            print(error)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set up the table's data source
        tableView.dataSource = self
        
        //Initialize the timer to "full"
        seconds = timerLength
        //Initialize the timer label
        timerLabel.text = timeString(time: TimeInterval(seconds))
        
        //TODO: hard-coded pin and comm boat for testing
        self.fleetMap["192.168.4.1:5000"] = Sailboat(id: "comm", pos: Position(GPST: 1.0, n: 0.0, e: 0.0, u: 0.0))
        self.fleetMap["192.168.4.2:5000"] = Sailboat(id: "pin", pos: Position(GPST: 1.0, n: 5.0, e: 5.0, u: 0.0))
        
        //Start the TCP server when the view loads on a separate high time precision thread
        DispatchQueue.global(qos: .userInteractive).async {
            self.runTCPServer()
        }
    }
}
