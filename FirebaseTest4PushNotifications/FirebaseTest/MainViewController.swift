//
//  MainViewController.swift
//  FirebaseTest
//
//  Created by Ivan Leider on 22/05/2017.
//  Copyright © 2017 BTS. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FBSDKCoreKit
class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UserTableViewCellDelegate, UISearchResultsUpdating {

    @IBOutlet weak var tableView: UITableView!
    var users = [User]()
    var filteredUsers = [User]()
    
    var db: DatabaseReference!
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        db = Database.database().reference()
        retrieveUsers()
        
        searchController.searchResultsUpdater = self
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filteredUsers = users.filter { user in
            if let name = user.name {
                return name.lowercased().contains(searchController.searchBar.text!.lowercased())
            }
            return false
        }
        
        tableView.reloadData()
    }
    
    func retrieveUsers() {
        db.child("users").queryOrderedByKey().observe(.value, with: { snapshot in
            if let users = snapshot.value as? [String: [String: String]] {
                self.users.removeAll()
                for (_, value) in users {
                    let user = User()
                    user.uid = value["uid"]
                    user.name = value["name"]
                    user.age = value["age"]
                    self.users.append(user)
                }
                self.tableView.reloadData()
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredUsers.count
        }
        return users.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as! UserTableViewCell
        let user: User
        if searchController.isActive && searchController.searchBar.text != "" {
           user = filteredUsers[indexPath.row]
        } else {
           user = users[indexPath.row]
        }
        cell.nameLabel.text = user.name
        cell.selectionStyle = .none
        cell.delegate = self
        if user.follow {
//            cell.accessoryType = .checkmark
            cell.followButton.setTitle("Unfollow", for: .normal)
        } else {
//            cell.accessoryType = .none
            cell.followButton.setTitle("Follow", for: .normal)
        }
        return cell
    }
    
    func userCellFollowButtonPressed(sender: UserTableViewCell) {
        if let indexPath = tableView.indexPath(for: sender) {
            let user: User
            if searchController.isActive && searchController.searchBar.text != "" {
                user = filteredUsers[indexPath.row]
            } else {
                user = users[indexPath.row]
            }
            user.follow = !user.follow
            tableView.reloadData()
        }
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        let user = users[indexPath.row]
//        user.follow = !user.follow
//        tableView.reloadData()
//        print("selected user " + (user.name ?? "Unknown"))
//    }

    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        defer {
            dismiss(animated: true, completion: nil)
        }
        do {
            try Auth.auth().signOut()
            FBSDKAccessToken.setCurrent(nil)
        } catch {
            
            
        }
    }
}







