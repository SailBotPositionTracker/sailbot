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
    
    var timerLength: Int = 3
    var seconds: Int = 0
    var timer: Timer = Timer()
    var isTimerRunning: Bool = false
    @IBOutlet weak var timerLabel: UILabel!
    
    //true: + distance is over the line, false: - distance is over the line
    var overLineDirection = true
    
    //map from TCP connection identifier to Sailboat object
    var fleetMap = [String: Sailboat]()
    
    //boilerplate for sailboat table section
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let data = Array(tableMap.values)
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = Array(tableMap)
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")!
        cell.textLabel?.text = data[indexPath.row].value
        
        let status = fleetMap[data[indexPath.row].key]!.getStatus()
        //define the table row color for each possible race status
        switch (status) {
            case Sailboat.raceStatus.over:
                cell.backgroundColor = UIColor.red
            case Sailboat.raceStatus.notstarted:
                cell.backgroundColor = UIColor.white
            case Sailboat.raceStatus.started:
                cell.backgroundColor = UIColor.green
            case Sailboat.raceStatus.cleared:
                cell.backgroundColor = UIColor.blue
        }
        return cell
    }
    
    
    @IBAction func swapLineButtonTapped(_ sender: UIButton) {
        //only allow line side swaps before the start of the race
        //TODO: could interfere with I flag
        if (seconds > 0) {
            overLineDirection = !overLineDirection
            for (clientId, sailboat) in fleetMap {
                if (sailboat.getId() != "pin") {
                    let dist_to_line = self.calcDistanceToLine(sailboat: sailboat)
                    let corrected_dist_to_line = (overLineDirection) ? dist_to_line : -dist_to_line
                    self.tableMap[clientId] = String(clientId) + ": " + (NSString(format: "%.2f", corrected_dist_to_line) as String) as String + "m"
                }
            }
            self.tableView.reloadData()
        }
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
        resetTimer()
    }
    
    @objc func updateTimer() {
        //store information about over the line boats at the moment of the start
        if (seconds == 1) {
            for (_, sailboat) in fleetMap {
                if (overLine(distance: calcDistanceToLine(sailboat: sailboat))) {
                    sailboat.setStatus(status: Sailboat.raceStatus.over)
                } else {
                    sailboat.setStatus(status: Sailboat.raceStatus.started)
                }
            }
            self.tableView.reloadData()
        }
        seconds -= 1
        timerLabel.text = timeString(seconds: seconds)
    }
    
    func resetTimer() {
        seconds = timerLength
        isTimerRunning = false
        timerLabel.text = timeString(seconds: seconds)
        //reset race status from current race
        for (_, sailboat) in fleetMap {
            sailboat.setStatus(status: Sailboat.raceStatus.notstarted)
        }
        self.tableView.reloadData()
    }
    
    func timeString(seconds: Int) -> String {
        let time = TimeInterval(abs(seconds))
        let min = Int(time) / 60 % 60
        let sec = Int(time) % 60
        let format_string = String(format:"%01i:%02i", min, sec)
        return ((seconds < 1) ? "+" : "-") + format_string
    }
    
    func overLine(distance: Double) -> Bool {
        return (overLineDirection && distance > 0) || (!overLineDirection && distance < 0)
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
    
    func runTCPClient() {
        //TODO this should be 192.168.4.1:9000 for real testing
        let client = TCPClient(address: "127.0.0.1", port: 5002)
        switch client.connect(timeout: 1) {
        case .success:
            while true {
                let d = client.read(53)
                if (d != nil) {
                    if let string_msg = String(bytes: d!, encoding: .utf8) {
                        do {
                            let clientId = String(string_msg.prefix(5))
                            if (self.fleetMap[clientId] == nil) {
                                self.fleetMap[clientId] = Sailboat()
                            }
                            //generate a Position from this RTKLIB string
                            let curpos = try Position(RTKLIBString: string_msg)
                            //set the Position of the corresponding Sailboat
                            self.fleetMap[clientId]!.setPosition(pos: curpos)
                            let dist_to_line = self.calcDistanceToLine(sailboat: self.fleetMap[clientId]!)
                            //define the text shown in the table
                            let corrected_dist_to_line = (overLineDirection) ? dist_to_line : -dist_to_line
                            self.tableMap[clientId] = String(clientId) + ": " + (NSString(format: "%.2f", corrected_dist_to_line) as String) as String + "m"
                            //if the race has started
                            if (seconds <= 0) {
                                //if a boat that was over has cleared, set its status to indicate this
                                if (self.fleetMap[clientId]!.getStatus() == Sailboat.raceStatus.over &&
                                    !overLine(distance: dist_to_line)) {
                                    self.fleetMap[clientId]!.setStatus(status: Sailboat.raceStatus.cleared)
                                }
                            }
                            //reload table data from main thread
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        } catch PositionError.InvalidStringFormat {
                            print("Invalid position string from RTKLIB")
                        } catch {
                            print("Unexpected error: \(error).")
                        }
                    }
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
        resetTimer()
        //TODO: hard-coded pin for testing
        self.fleetMap["192.168.4.2:5000"] = Sailboat(id: "pin", pos: Position(GPST: 1.0, n: 5.0, e: 5.0, u: 0.0))
        //Start the TCP server when the view loads on a separate high time precision thread
        DispatchQueue.global(qos: .userInteractive).async {
            self.runTCPClient()
        }
    }
}
