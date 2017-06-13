//
//  MasterViewController.swift
//  Coratem
//
//  Created by Sachin Raut on 08/05/17.
//  Copyright © 2017 Sachin Raut. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate
{

    var sortType = "date"
    
    let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var _fetchResultsController: NSFetchedResultsController<BorrowItem>?=nil
    
    var fetchedResultsController: NSFetchedResultsController<BorrowItem>
    {
        if _fetchResultsController != nil
        {
            return _fetchResultsController!
        }
        
        let fetchRequest: NSFetchRequest<BorrowItem> = BorrowItem.fetchRequest()
        
        //set the batch size
        
        fetchRequest.fetchBatchSize = 20
        
        //edit the sort key as appropriate
        
        let sortDescriptor = NSSortDescriptor(key: "endDate", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: "person.name", cacheName: "Master")
        
        aFetchedResultsController.delegate = self
        
        _fetchResultsController = aFetchedResultsController
        
        do
        {
            try _fetchResultsController!.performFetch()
        }
        catch
        {
            let nserror = error as NSError
            
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return _fetchResultsController!
    } // end of computed property
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
    }

    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if sortType == "date"
        {
            return nil
        }
        else
        {
            if let sectionInfo = fetchedResultsController.sections?[section]
            {
                return sectionInfo.name
            }
        }
        return nil
    }
    
    
    
    @IBAction func sortingChanged(_ sender: UISegmentedControl)
    {
        if sender.selectedSegmentIndex == 0
        {
            sortType = "date"
        }
        else
        {
            sortType = "person"
        }
        tableView.reloadData()
    }
    
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let borrowItemObject = self.fetchedResultsController.object(at: indexPath)
        
        //cell.textLabel?.text = borrowItemObject.title
        
        configureCell(cell, withBorrowItem: borrowItemObject)
        
        return cell
    }
    
    
    func configureCell(_ cell: UITableViewCell, withBorrowItem borrowItem: BorrowItem)
    {
        cell.textLabel?.text = borrowItem.title
        
        if let availableImageData = borrowItem.image as Data?
        {
            cell.imageView?.image = UIImage(data: availableImageData)
        }
        
        if let startDate = borrowItem.startDate as Date?
        {
            if let endDate = borrowItem.endDate as Date?
            {
                let dateFormatter = DateFormatter()
                
                dateFormatter.dateFormat = "dd/MM/yyyy"
                
                cell.detailTextLabel?.text = "Borrowed at - \(dateFormatter.string(from: startDate)) : Return at - \(dateFormatter.string(from: endDate))"
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "showDetail"
        {
            if let indexPath = self.tableView.indexPathForSelectedRow
            {
                let object = self.fetchedResultsController.object(at: indexPath)
                
                let detailTableVC = (segue.destination as! UINavigationController).topViewController as! DetailTableViewController
                
                detailTableVC.detailItem = object
            }
        }
    }
    

    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        self.tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type
        {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            
        default:
            self.configureCell(tableView.cellForRow(at: indexPath!)!, withBorrowItem: anObject as! BorrowItem)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)

            
        case .delete:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)

        default:
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            let context = self.fetchedResultsController.managedObjectContext
            
            context.delete(self.fetchedResultsController.object(at: indexPath))
        
            do
            {
                try context.save()
            }
            catch
            {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    

}











