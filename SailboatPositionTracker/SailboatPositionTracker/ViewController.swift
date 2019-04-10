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
    
    @IBOutlet weak var pinIDLabel: UILabel!
    @IBOutlet weak var pinELabel: UILabel!
    @IBOutlet weak var pinNLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    //true: + distance is over the line, false: - distance is over the line
    var overLineDirection = true
    
    //map from TCP connection identifier to Sailboat object
    var fleetMap = [String: Sailboat]()
    
    //boilerplate for sailboat table section
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    //delete an element from the table
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let tableIndex = Array(tableMap.keys)[indexPath.row]
            fleetMap.removeValue(forKey: tableIndex)
            tableMap.removeValue(forKey: tableIndex)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
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
                cell.textLabel?.textColor = UIColor.black
            case Sailboat.raceStatus.notstarted:
                cell.backgroundColor = UIColor.black
                cell.textLabel?.textColor = UIColor.white
            case Sailboat.raceStatus.started:
                cell.backgroundColor = UIColor.green
                cell.textLabel?.textColor = UIColor.black
            case Sailboat.raceStatus.cleared:
                cell.backgroundColor = UIColor.blue
                cell.textLabel?.textColor = UIColor.black
        }
        return cell
    }
    
    @IBOutlet var ubeView: UIView!
    @IBOutlet var leadingC: NSLayoutConstraint!
    @IBOutlet var trailingC: NSLayoutConstraint!
    var settingsMenuIsVisible = false
    
    @IBAction func hamburgerBtnTapped(_ sender: Any) {
        if !settingsMenuIsVisible {
            leadingC.constant = 300
            trailingC.constant = -300
        } else {
            leadingC.constant = 0
            trailingC.constant = 0
        }
        settingsMenuIsVisible = !settingsMenuIsVisible
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func addPinButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Add/Change Pin",
                                      message: "Enter the new pin's tracker ID.",
                                      preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "OK",
                               style: UIAlertAction.Style.default) { (action: UIAlertAction) in
                                let clientId = alert.textFields![0].text
                                if (clientId != "") {
                                    //remove old pin and add new pin
                                    for tracker_id in self.fleetMap.keys {
                                        if self.fleetMap[tracker_id]!.id == "PIN" {
                                            self.fleetMap.removeValue(forKey: tracker_id)
                                            break
                                        }
                                    }
                                    self.fleetMap[clientId!] = Sailboat(id: "PIN")
                                    self.pinTableText(clientId: clientId!)
                                }
        }
        let cancel = UIAlertAction(title: "Cancel",
                                   style: UIAlertAction.Style.cancel,
                                   handler: nil)
        alert.addTextField { (textField: UITextField) in textField.placeholder = "Tracker ID"; textField.keyboardType = .numberPad }
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func swapLineButtonTapped(_ sender: UIButton) {
        //only allow line side swaps before the start of the race
        //TODO: could interfere with I flag
        if (seconds > 0) {
            overLineDirection = !overLineDirection
            for (clientId, sailboat) in fleetMap {
                if (sailboat.getId() != "PIN") {
                    let dist_to_line = self.calcDistanceToLine(sailboat: sailboat)
                    self.tableMap[clientId] = self.sailboatTableText(clientId: clientId, dist: dist_to_line)
                }
            }
            self.tableView.reloadData()
        }
    }
    
    @IBAction func addBoatButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Add Boat",
                                      message: "Enter your sail number and fleet.",
                                      preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "OK",
                               style: UIAlertAction.Style.default) { (action: UIAlertAction) in
                                let trackerField = alert.textFields![0]
                                let sailNumberField = alert.textFields![1]
                                let fleetField = alert.textFields![2]
                                let clientId = trackerField.text
                                //don't allow pin to be reassigned by sailNumber or tracker ID
                                if (clientId != "") && (sailNumberField.text != "") && (sailNumberField.text != "PIN") && (fleetField.text != "") && (self.getPinID() != clientId!) {
                                    self.fleetMap[clientId!] = Sailboat(id: sailNumberField.text!, fleet: fleetField.text!)
                                    self.tableMap[clientId!] = String(clientId!)
                                    //reload table data from main thread
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                }
        }
        let cancel = UIAlertAction(title: "Cancel",
                                   style: UIAlertAction.Style.cancel,
                                   handler: nil)
        alert.addTextField { (textField: UITextField) in textField.placeholder = "Tracker ID"; textField.keyboardType = .numberPad }
        alert.addTextField { (textField: UITextField) in textField.placeholder = "Sail Number"; textField.keyboardType = .numberPad }
        alert.addTextField { (textField: UITextField) in textField.placeholder = "Fleet" }
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        if !isTimerRunning {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            startStopButton.backgroundColor = UIColor.red
        } else {
            timer.invalidate()
            startStopButton.backgroundColor = UIColor.green
        }
        isTimerRunning = !isTimerRunning
    }
    
    @IBAction func resetButtonTapped(_ sender: UIButton) {
        timer.invalidate()
        resetTimer()
        startStopButton.backgroundColor = UIColor.green
    }
    
    @objc func updateTimer() {
        //store information about over the line boats at the moment of the start
        if (seconds == 1) {
            for (_, sailboat) in fleetMap {
                let dist = calcDistanceToLine(sailboat: sailboat)
                if (dist != nil) {
                    if (dist! > 0) {
                        sailboat.setStatus(status: Sailboat.raceStatus.over)
                    } else {
                        sailboat.setStatus(status: Sailboat.raceStatus.started)
                    }
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

    func getPinID() -> String? {
        for tracker_id in fleetMap.keys {
            if fleetMap[tracker_id]!.id == "PIN" {
                return tracker_id
            }
        }
        return nil
    }
    
    func getPin() -> Sailboat? {
        let pin_id = getPinID()
        if (pin_id == nil) {
            return nil
        }
        return fleetMap[pin_id!]
    }
    
    func pinTableText(clientId: String) {
        self.pinIDLabel.text = "ID: " + clientId
        let pos = self.fleetMap[clientId]!.getPosition()
        if (pos != nil) {
            self.pinELabel.text = "E: " + (NSString(format: "%.2f", pos!.getE()) as String) + " m"
            self.pinNLabel.text = "N: " + (NSString(format: "%.2f", pos!.getN()) as String) + " m"
        } else {
            self.pinELabel.text = ""
            self.pinNLabel.text = ""
        }
    }
    
    func sailboatTableText(clientId: String, dist: Double?) -> String {
        if (dist != nil) {
            return String(clientId) + ": " + (NSString(format: "%.2f", dist!) as String) as String + "m"
        } else {
            return String(clientId)
        }
    }
    
    func calcDistanceToLine(sailboat: Sailboat) -> Double? {
        //if relative to the committee boat (assuming base tracker is at (0, 0) at line boat end)
        let pin = getPin()
        if (pin != nil) {
            let pos_pin = pin!.getPosition()
            if (pos_pin != nil) {
                let n_pin = pos_pin!.getN()
                let e_pin = pos_pin!.getE()
                //corner case when base and pin are identically positioned
                if (n_pin == 0) && (e_pin == 0) {
                    return 0
                }
                let pos_sail = sailboat.getPosition()
                let n_sail = pos_sail!.getN()
                let e_sail = pos_sail!.getE()
                let dist = ((n_sail * e_pin) - (e_sail * n_pin)) / sqrt(pow(n_pin, 2) + pow(e_pin, 2))
                //using positions of both pin and committee boat
                /*
                let num = ((n_sail - n_comm) * (e_pin - e_comm) - (e_sail - e_comm) * (n_pin - n_comm))
                let den = sqrt(pow((n_pin - n_comm), 2) + pow((e_pin - e_comm), 2))
                 */
                return (dist == 0) ? 0 : ((overLineDirection) ? dist : -dist)
            } else {
                //if the pin currently defined has not received a position
                return nil
            }
        } else {
            //if no pin is currently defined, return nil
            return nil
        }
        
    }
    
    func runTCPClient() {
        //TODO this should be 192.168.4.1:9000 for real testing
        let client = TCPClient(address: "192.168.4.1", port: 9000)
        switch client.connect(timeout: 1) {
        case .success:
            while true {
                let d = client.read(54)
                if (d != nil) {
                    if let string_msg = String(bytes: d!, encoding: .utf8) {
                        do {
                            let clientId = String(string_msg.prefix(5))
                            let cur_boat = self.fleetMap[clientId]
                            //only update information for boats already in the system
                            if (cur_boat != nil) {
                                //generate a Position from this RTKLIB string
                                let cur_pos = try Position(RTKLIBString: string_msg)
                                //set the Position of the corresponding Sailboat
                                cur_boat!.setPosition(pos: cur_pos)
                                //if we're getting data for the pin
                                if (cur_boat!.getId() == "PIN") {
                                    pinTableText(clientId: clientId)
                                } else { //if we're getting data for a boat
                                    let dist_to_line = self.calcDistanceToLine(sailboat: cur_boat!)
                                    //define the text shown in the table
                                    self.tableMap[clientId] = sailboatTableText(clientId: clientId, dist: dist_to_line)
                                    //if the race has started
                                    if (seconds <= 0 && dist_to_line != nil) {
                                        //if a boat that was over has cleared, set its status to indicate this
                                        if (cur_boat!.getStatus() == Sailboat.raceStatus.over && dist_to_line! <= 0) {
                                            cur_boat!.setStatus(status: Sailboat.raceStatus.cleared)
                                        }
                                    }
                                }
                                //reload table data from main thread
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
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
        
        //Start the TCP server when the view loads on a separate high time precision thread
        DispatchQueue.global(qos: .userInteractive).async {
            self.runTCPClient()
        }
    }
}
