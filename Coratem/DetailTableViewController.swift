//
//  DetailTableViewController.swift
//  Coratem
//
//  Created by Sachin Raut on 08/05/17.
//  Copyright © 2017 Sachin Raut. All rights reserved.
//

import UIKit
import CoreData

class DetailTableViewController: UITableViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate, TimeFrameDelegate, MLPAutoCompleteTextFieldDelegate, MLPAutoCompleteTextFieldDataSource
{
    @IBOutlet var itemTitleTextField: UITextField!
    @IBOutlet var itemImageView: UIImageView!
    @IBOutlet var borrowedAtLabel: UILabel!
    @IBOutlet var returnAtLabel: UILabel!
    @IBOutlet var personImageView: UIImageView!
    @IBOutlet var personNameTextField: MLPAutoCompleteTextField!
 
    
    var startDate: NSDate?
    var endDate: NSDate?
    
    
    var moc: NSManagedObjectContext!
    
    var detailItem: BorrowItem?
    {
        didSet
        {
            self.configureView()
        }
    }
    
    var personImageAdded = false
    var itemImageAdded = false
    
    enum PicturePurpose
    {
        case item
        case person
    }
    
    var picturePurposeSelector: PicturePurpose = .item
    
    func addPictureForItem()
    {
        picturePurposeSelector = .item
        addImageWithPurpose()
    }
    
    func addPictureForPerson()
    {
        picturePurposeSelector = .person
        addImageWithPurpose()
    }
    
    func addImageWithPurpose()
    {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        
        imagePickerController.sourceType = .photoLibrary
        
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    func configureView()
    {
        if let titleTextField = itemTitleTextField
        {
            if let borrowItem = detailItem
            {
                titleTextField.text = borrowItem.title
                
                if let availableImageData = borrowItem.image as Data?
                {
                    itemImageView.image = UIImage(data: availableImageData)
                }
                
                let dateFormatter = DateFormatter()
                
                dateFormatter.dateFormat = "dd/MM/yyyy"
                
                if let availableStartDate = detailItem?.startDate as Date?
                {
                    borrowedAtLabel.text = "Borrowed at - \(dateFormatter.string(from: availableStartDate))"
                }
                
                if let availableEndDate = detailItem?.endDate as Date?
                {
                    returnAtLabel.text = "Return at - \(dateFormatter.string(from: availableEndDate))"
                }
                
                if let associatedPerson = borrowItem.person
                {
                    personNameTextField.text = associatedPerson.name
                    
                    if let personImageData = associatedPerson.image as Data?
                    {
                        personImageView.image = UIImage(data: personImageData)
                    }
                }
                
            }
        }
    }
    
    @IBAction func chooseTimeFrameButtonPressed(_ sender: Any)
    {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "showTimeframe"
        {
            let timeframeVC = segue.destination as! TimeframeViewController
            
            timeframeVC.timeFrameDelegate = self
        }
    }
    
    func didSelectDateRange(range: GLCalendarDateRange)
    {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        borrowedAtLabel.text = "Borrowed at - \(dateFormatter.string(from: range.beginDate))"
        
        returnAtLabel.text = "Return at - \(dateFormatter.string(from: range.endDate))"
        
        startDate = range.beginDate as NSDate
        
        endDate = range.endDate as NSDate
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any)
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    @IBAction func saveButtonPressed(_ sender: Any)
    {
        if detailItem == nil
        {
            //create a new borrow item
            
            let borrowItem = BorrowItem(context: moc)
            
            if itemTitleTextField.text != nil
            {
                borrowItem.title = itemTitleTextField.text
                
                if let itemImage = itemImageView.image
                {
                    borrowItem.image = NSData(data: UIImageJPEGRepresentation(itemImage, 0.3)!)
                }
                
                if let availableStartDate = startDate
                {
                    borrowItem.startDate = availableStartDate
                }
                
                if let availableEndDate = endDate
                {
                    borrowItem.endDate = availableEndDate
                }
            }
            
            //person information
            
            let personRequest: NSFetchRequest<Person> = Person.fetchRequest()
            
            if let name = personNameTextField.text
            {
                personRequest.predicate = NSPredicate(format: "name == %@", name)
            }
            
            personRequest.fetchLimit = 1
            
            let numberOfResults = try! moc.count(for: personRequest)
            
            if numberOfResults == 0
            {
                //create a new person & add borrow item
                
                let newPerson = Person(context: moc)
                
                newPerson.name = personNameTextField.text
                
                if let personImageToSave = personImageView.image
                {
                    newPerson.image = NSData(data: UIImageJPEGRepresentation(personImageToSave, 0.3)!)
                }
                
                //now add borrow item to person
                
                newPerson.addToBorrowItem(borrowItem)
            }
            else
            {
                //add borrow item to existing person
                
                var items = [Person]()
                
                do
                {
                    try items = moc.fetch(personRequest)
                }
                catch
                {
                    print(error.localizedDescription)
                }
                
                if let foundPerson = items.first
                {
                    foundPerson.addToBorrowItem(borrowItem)
                }
                
            }
        }
        else
        {
            // update an existing item & we are allowing to update timeframe
        
            if let availableStartDate = startDate
            {
                detailItem?.startDate = availableStartDate
            }
            
            if let availableEndDate = endDate
            {
                detailItem?.endDate = availableEndDate
            }
            
        }
        do
        {
            try moc.save()
            print("saved successfully")
            self.dismiss(animated: true, completion: nil)
        }
        catch
        {
            print(error.localizedDescription)
        }
        
    }
    
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        
        personNameTextField.autoCompleteDelegate = self
        
        personNameTextField.autoCompleteDataSource = self
        
        personNameTextField.autoCompleteTableAppearsAsKeyboardAccessory = true
        
        personNameTextField.autoCompleteTableBackgroundColor = UIColor.white
        
        
        let itemGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DetailTableViewController.addPictureForItem))
        
        itemImageView.addGestureRecognizer(itemGestureRecognizer)
        
        let personGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DetailTableViewController.addPictureForPerson))
        
        personImageView.addGestureRecognizer(personGestureRecognizer)
        
        self.configureView()
    }

    
    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, possibleCompletionsFor string: String!) -> [Any]!
    {
        //provide already existing persons
        
        let fetchRequest: NSFetchRequest<Person> = Person.fetchRequest()
        
        var personObjects = [Person]()
        
        do
        {
            personObjects = try moc.fetch(fetchRequest)
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        //now extract only person name
        
        var nameArray = [String]()
        
        for person in personObjects
        {
            if let name = person.name
            {
                nameArray.append(name)
            }
        }
        return nameArray
    }
    
    
    func autoCompleteTextField(_ textField: MLPAutoCompleteTextField!, didSelectAutoComplete selectedString: String!, withAutoComplete selectedObject: MLPAutoCompletionObject!, forRowAt indexPath: IndexPath!)
    {
        //when a cell is selected, fill person name & person image. lets find the person first
        
        let predicate = NSPredicate(format: "name == %@", selectedString)
        
        let fetchRequest: NSFetchRequest<Person> = Person.fetchRequest()
        
        fetchRequest.predicate = predicate
        
        var selectedPerson: Person?
        
        do
        {
            selectedPerson = try moc.fetch(fetchRequest).first
        }
        catch
        {
            print(error.localizedDescription)
        }
        
        if let imageData = selectedPerson?.image as? Data
        {
            personImageView.image = UIImage(data: imageData)
        }
    }
    
    
    //implement image picker controller delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            //create scaled image. Add "UIImage+Scale.swift"
            
            let scaledImage = UIImage.scaleImage(image: image, toWidth: 120, andHeight: 120)
            
            if picturePurposeSelector == .item
            {
                itemImageView.image = scaledImage
                itemImageAdded = true
            }
            else
            {
                personImageView.image = scaledImage
                personImageAdded = true
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion: nil)
    }
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
