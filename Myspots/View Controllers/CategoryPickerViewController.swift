import UIKit

class CategoryPickerViewController: UITableViewController {
  var selectedCategoryName = ""
  
  let categories = [
    "No Category",
    "Spot to do",
    "Spots completed",
    "Jumps",
    "Dirts",
    "Drops",
    "Rolleys",
    "Steps",
    "Bike Parks",
    "Flow Lines",
    "Place for obstacles"
  ]
  
  var selectedIndexPath = IndexPath()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    for i in 0..<categories.count {
      if categories[i] == selectedCategoryName {
        selectedIndexPath = IndexPath(row: i, section: 0)
        break
      }
    }
  }
  
  // MARK:- Table View Delegates
  override func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
    return categories.count
  }
  
  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) ->
    UITableViewCell {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: "Cell",
        for: indexPath)
      
      let categoryName = categories[indexPath.row]
      cell.textLabel!.text = categoryName
      
      if categoryName == selectedCategoryName {
        cell.accessoryType = .checkmark
      } else {
        cell.accessoryType = .none
      }
      let selection = UIView(frame: CGRect.zero)
      selection.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
      cell.selectedBackgroundView = selection
      return cell
    
    }

  override func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath) {
    if indexPath.row != selectedIndexPath.row {
      if let newCell = tableView.cellForRow(at: indexPath) {
        newCell.accessoryType = .checkmark
      }
      if let oldCell = tableView.cellForRow(
        at: selectedIndexPath) {
        oldCell.accessoryType = .none
      }
      selectedIndexPath = indexPath
    }
  }
  
  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "PickedCategory" {
      let cell = sender as! UITableViewCell
      if let indexPath = tableView.indexPath(for: cell) {
        selectedCategoryName = categories[indexPath.row]
      }
    }
  }
  
}
