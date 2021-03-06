//
//  ViewController.swift
//  SailboatPositionTracker
//
//  Created by Tom Frikker on 1/9/19.
//  Copyright © 2019 TuftsSP2019. All rights reserved.
//

import UIKit
import SwiftSocket

class ViewController: UIViewController, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    private var tableMap: [String] = []
    
    var timerLength: Int = 180
    var seconds: Int = 0
    var timer: Timer = Timer()
    var isTimerRunning: Bool = false
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var pinIDLabel: UILabel!
    @IBOutlet weak var pinELabel: UILabel!
    @IBOutlet weak var pinNLabel: UILabel!
    @IBOutlet weak var startStopButton: UIButton!
    //true: + distance is over the line, false: - distance is over the line
    var overLineDirection = true
    
    //map from TCP connection identifier to Sailboat object
    var fleetMap = [String: Sailboat]()
    var pin: Sailboat?
    var pin_id: String?
    
    @IBOutlet weak var courseSideLabel: UILabel!
    @IBAction func swapCourseSide(_ sender: Any) {
        //TODO: could interfere with I flag
        overLineDirection = !overLineDirection
        if (sortType == 3) {
            sortTable()
        }
        if (overLineDirection) {
            courseSideLabel.text = "Course Side: Upwind"
        } else {
            courseSideLabel.text = "Course Side: Downwind"
        }
        self.tableView.reloadData()
    }
    //sorting functions
    var sortType = 0
    func sorterForDistance(boat1:String, boat2:String) -> Bool {
        let dist1 = calcDistanceToLine(sailboat: self.fleetMap[boat1]!)
        let dist2 = calcDistanceToLine(sailboat: self.fleetMap[boat2]!)
        if (dist1 == nil) && (dist2 == nil) {
            return boat1 < boat2
        }
        if (dist1 == nil) {
            return true
        }
        if (dist2 == nil) {
            return false
        }
        return dist1! < dist2!
    }
    @IBAction func sortTableById(_ sender: UIButton) {
        sortType = 0
        sortTable()
        self.tableView.reloadData()
    }
    @IBAction func sortTableBySailNumber(_ sender: UIButton) {
        sortType = 1
        sortTable()
        self.tableView.reloadData()
    }
    @IBAction func sortTableByFleet(_ sender: UIButton) {
        sortType = 2
        sortTable()
        self.tableView.reloadData()
    }
    @IBAction func sortTableByDistance(_ sender: UIButton) {
        sortType = 3
        sortTable()
        self.tableView.reloadData()
    }
    func sortTable() {
        switch(sortType) {
            case 1: tableMap = tableMap.sorted(by: { self.fleetMap[$0]!.getId() < self.fleetMap[$1]!.getId() })
            case 2: tableMap = tableMap.sorted(by: { self.fleetMap[$0]!.getFleet() < self.fleetMap[$1]!.getFleet() })
            case 3: tableMap = tableMap.sorted(by: sorterForDistance)
            default: tableMap = tableMap.sorted(by: { $0 < $1 })
        }
    }
    
    //picker functions
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var pickerColon: UILabel!
    var pickerData: [[String]] = [["0", "1", "2", "3", "4", "5"], ["00", "15", "30", "45"]]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        //number of columns of data
        return 2
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //number of rows of data
        return pickerData[component].count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //data to return for the row and component (column) that's being passed in
        return pickerData[component][row]
    }
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        //width of columns
        switch (component) {
            case 0: return CGFloat(60.0)
            default: return CGFloat(100.0)
        }
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        //height of rows
        return CGFloat(70.0)
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        //label size
        var pickerLabel: UILabel? = (view as? UILabel)
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont (name: "Helvetica Neue", size: 76)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = pickerData[component][row]
        pickerLabel?.textColor = UIColor.white
        
        return pickerLabel!
    }
    
    //tableview functions
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //delete an element from the table
        if editingStyle == .delete {
            let tableIndex = tableMap[indexPath.row]
            fleetMap.removeValue(forKey: tableIndex)
            tableMap.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableMap.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")!
        cell.textLabel?.text = sailboatTableText(clientId: tableMap[indexPath.row])
        
        let status = fleetMap[tableMap[indexPath.row]]!.getStatus()
        //define the table row color for each possible race status
        cell.textLabel?.font = UIFont (name: "Menlo", size: 20)
        switch (status) {
            case Sailboat.raceStatus.over:
                cell.backgroundColor = UIColor.red
                cell.textLabel?.textColor = UIColor.black
            case Sailboat.raceStatus.none:
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
    
    //settings pane functions
    @IBOutlet var ubeView: UIView!
    @IBOutlet var leadingC: NSLayoutConstraint!
    @IBOutlet var trailingC: NSLayoutConstraint!
    var settingsMenuIsVisible = false
    @IBAction func hamburgerBtnTapped(_ sender: Any) {
        if !settingsMenuIsVisible {
            leadingC.constant = 350
            trailingC.constant = -350
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
                                    var used: Bool = false
                                    for tracker_id in self.fleetMap.keys {
                                        if tracker_id == clientId! {
                                            used = true
                                        }
                                    }
                                    if (!used) {
                                        self.pin = Sailboat()
                                        self.pin_id = clientId!
                                        self.setPinText()
                                        self.infoLabel.text = self.infoLabelText()
                                    }
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
                                if (clientId != "") && (sailNumberField.text != "") && (fleetField.text != "") && (self.pin_id != clientId!) {
                                    self.fleetMap[clientId!] = Sailboat(id: sailNumberField.text!, fleet: fleetField.text!)
                                    self.tableMap.append(clientId!)
                                    self.sortTable()
                                    self.tableView.reloadData()
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
        if (!self.picker.isHidden) {
            let min_idx: Int = self.picker.selectedRow(inComponent: 0)
            let sec_idx: Int = self.picker.selectedRow(inComponent: 1)
            let min: Int = Int(self.pickerData[0][min_idx])!
            let sec: Int = Int(self.pickerData[1][sec_idx])!
            self.timerLength = (60 * min) + sec
            self.seconds = self.timerLength
            timerLabel.text = timeString(seconds: seconds)
            self.picker.isHidden = true
            self.pickerColon.isHidden = true
        }
        if !isTimerRunning {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
            startStopButton.backgroundColor = UIColor.red
            startStopButton.setTitle("Stop", for: .normal)
        } else {
            timer.invalidate()
            startStopButton.backgroundColor = UIColor.green
            startStopButton.setTitle("Start", for: .normal)
        }
        isTimerRunning = !isTimerRunning
    }
    
    @IBAction func resetButtonTapped(_ sender: UIButton) {
        timer.invalidate()
        resetTimer()
        startStopButton.backgroundColor = UIColor.green
        startStopButton.setTitle("Start", for: .normal)
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
        self.picker.isHidden = false
        self.pickerColon.isHidden = false
        seconds = timerLength
        isTimerRunning = false
        timerLabel.text = timeString(seconds: seconds)
        //reset race status from current race
        for (_, sailboat) in fleetMap {
            sailboat.setStatus(status: Sailboat.raceStatus.none)
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
    
    func setPinText() {
        self.pinIDLabel.text = "ID: " + self.pin_id!
        let pos = self.pin!.getPosition()
        if (pos != nil) {
            self.pinELabel.text = "E: " + (NSString(format: "%.2f", pos!.getE()) as String) + " m"
            self.pinNLabel.text = "N: " + (NSString(format: "%.2f", pos!.getN()) as String) + " m"
        } else {
            self.pinELabel.text = ""
            self.pinNLabel.text = ""
        }
    }
    
    func sailboatTableText(clientId: String) -> String {
        let sailboat = self.fleetMap[clientId]!
        let dist = calcDistanceToLine(sailboat: sailboat)
        let track_id = String(clientId).padding(toLength: 7, withPad: " ", startingAt: 0)
        let id = sailboat.getId().padding(toLength: 20, withPad: " ", startingAt: 0)
        let fleet = sailboat.getFleet().padding(toLength: 16, withPad: " ", startingAt: 0)
        let base_info = track_id + id + fleet
        if (dist != nil) {
            //max: <-999.99m = 9 chars
            var dist_formatted = ""
            if (dist! < -999.99) {
                dist_formatted = "<-999.99m"
            } else if (dist! > 999.99) {
                dist_formatted = ">999.99m "
            } else {
                dist_formatted = ((NSString(format: "%.2f", dist!) as String) as String + "m").padding(toLength: 9, withPad: " ", startingAt: 0)
            }
            return base_info + dist_formatted
        } else {
            return base_info
        }
    }
    
    func infoLabelText() -> String {
        if (self.pin == nil) {
            return "No pin defined"
        }
        if (self.pin!.getPosition() == nil) {
            return "No pin position data"
        }
        if (fleetMap.count == 0) {
            return "No boats in fleet"
        }
        var total_valid = 0
        var count_over = 0
        for tracker_id in fleetMap.keys {
            let tracker = fleetMap[tracker_id]!
            let dist_to_line = calcDistanceToLine(sailboat: tracker)
            if (dist_to_line != nil) {
                total_valid += 1
                if (dist_to_line! > 0) {
                    count_over += 1
                }
            }
        }
        if (total_valid == 0) {
            return "No boat position data"
        } else {
            return (NSString(format: "%.0f", (count_over / total_valid)) as String) + "% over"
        }
    }
    
    func calcDistanceToLine(sailboat: Sailboat) -> Double? {
        //if relative to the committee boat (assuming base tracker is at (0, 0) at line boat end)
        let pin = self.pin
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
                                let dist_to_line = self.calcDistanceToLine(sailboat: cur_boat!)
                                infoLabel.text = infoLabelText()
                                //if the race has started
                                if (seconds <= 0 && dist_to_line != nil) {
                                    //if a boat that was over has cleared, set its status to indicate this
                                    if (cur_boat!.getStatus() == Sailboat.raceStatus.over && dist_to_line! <= 0) {
                                        cur_boat!.setStatus(status: Sailboat.raceStatus.cleared)
                                    }
                                }
                                sortTable()
                                //reload table data from main thread
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            } else if (self.pin_id != nil && clientId == self.pin_id) {
                                let cur_pos = try Position(RTKLIBString: string_msg)
                                self.pin!.setPosition(pos: cur_pos)
                                setPinText()
                                //TODO: reload position for every boat
                                sortTable()
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
        infoLabel.text = infoLabelText()
        
        //Set up the time picker's data source
        self.picker.delegate = self
        self.picker.dataSource = self
        //set timer default to 3:00
        self.picker.selectRow(3, inComponent: 0, animated: true)
        self.picker.selectRow(0, inComponent: 1, animated: true)
        //self.picker.alpha = 1
        
        //Set up the table's data source
        tableView.dataSource = self
        resetTimer()
        
        //Start the TCP server when the view loads on a separate high time precision thread
        DispatchQueue.global(qos: .userInteractive).async {
            self.runTCPClient()
        }
    }
}
