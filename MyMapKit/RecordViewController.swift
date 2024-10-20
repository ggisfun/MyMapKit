//
//  RecordViewController.swift
//  MyMapKit
//
//  Created by Adam Chen on 2024/10/20.
//

import UIKit
import CoreData

class RecordViewController: UIViewController {

    @IBOutlet weak var recordTableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    var container: NSPersistentContainer!
    var records = [Record]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getRecordDate()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func getRecordDate(_ text: String? = nil) {
        let request = Record.fetchRequest()
        
        if let text {
            request.predicate = NSPredicate(format: "place CONTAINS[c] %@", text)
        }
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Record.date, ascending: false)
        ]
        
        let context = container.viewContext
        do {
            records = try context.fetch(request)
        } catch {
            print("Error fetching records: \(error)")
        }
        recordTableView.reloadData()
    }
    
    @IBAction func searchRecord(_ sender: Any) {
        guard let text = searchTextField.text else { return }
        guard text.trimmingCharacters(in: .whitespaces).isEmpty == false else { return }
        
        getRecordDate(text)
        view.endEditing(true)
        searchTextField.text = nil
    }
    
    @IBAction func researchRecord(_ sender: Any) {
        getRecordDate()
    }
    
    func updateRecord(_ record: Record) {
        
        let context = self.container.viewContext
        let objectID = record.objectID
        do {
            let object = try context.existingObject(with: objectID)
            object.setValue(record.content, forKey: "content")
            self.container.saveContext()
        } catch {
            print(error)
        }
    }

}

extension RecordViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecordTableViewCell.identifier, for: indexPath) as! RecordTableViewCell
        
        let record = records[indexPath.row]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
        
        cell.placeNameLabel.text = record.place
        cell.addressLabel.text = record.address
        cell.dateTimeLabel.text = dateFormatter.string(from: record.date!)
        cell.contentLabel.text = record.content
        
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let record = self.records[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .normal, title: "刪除") { (action, view, completionHandler) in
            
            let context = self.container.viewContext
            context.delete(record)
            self.container.saveContext()
            self.records.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            
            completionHandler(true)
        }
        // 按鈕背景顏色
        deleteAction.backgroundColor = .systemRed
        
        let editedAction = UIContextualAction(style: .normal, title: "編輯") { (action, view, completionHandler) in
            
            let alertController = UIAlertController(title: record.place, message: record.address, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                let content = alertController.textFields?.first?.text
                guard let content else { return }
                guard content != "" else { return }
                record.content = content
                self.updateRecord(record)
                tableView.reloadData()
            }
            alertController.addAction(okAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alertController.addAction(cancelAction)
            alertController.addTextField { textField in
                textField.text = record.content
            }
            self.present(alertController, animated: true, completion: nil)
            
            completionHandler(true)
        }
        // 按鈕背景顏色
        editedAction.backgroundColor = .systemOrange
        
        let prevention = UISwipeActionsConfiguration(actions: [deleteAction, editedAction])
        prevention.performsFirstActionWithFullSwipe = false
        
        return prevention
    }
}
