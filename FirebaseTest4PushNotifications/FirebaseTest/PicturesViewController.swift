//
//  PicturesViewController.swift
//  FirebaseTest
//
//  Created by Ivan Leider on 29/05/2017.
//  Copyright © 2017 BTS. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseDatabase

class PicturesViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    var pictureURLs = [String]()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pictureURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PictureCell", for: indexPath) as! PictureCollectionViewCell
        cell.pictureImageView.image = UIImage()
        // download the picture
        cell.pictureImageView.downloadImage(from: pictureURLs[indexPath.item])
        return cell
        
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var picker = UIImagePickerController()
    var db: DatabaseReference!
    var userStorage: StorageReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        db = Database.database().reference()
        let storage = Storage.storage().reference(forURL: "gs://fir-test-5673c.appspot.com")
        userStorage = storage.child("pictures")
        db.child("pictures").observe(.value, with: { snapshot in
            if let val = snapshot.value as? [String: [String: String]] {
                self.pictureURLs = [String]()
                for (_, picture) in val {
                    if let url = picture["url"]{
                        self.pictureURLs.append(url)
                    }
                }
                self.collectionView.reloadData()
            }
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true) {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                
                // UPLOAD PIC TO STORAGE
                
                // get jpg representation from image
                let jpeg = UIImageJPEGRepresentation(image, 0.8)
                
                // generate a name for my new image to be uploaded
                let name = self.db.child("pictures").childByAutoId().key
                // create a reference for the image to be uploaded
                let imageRef = self.userStorage.child("\(name).jpg")
                // create an async task to upload the image
                let uploadTask = imageRef.putData(jpeg!, metadata: nil, completion: { (metadata, error) in
                    // when the upload finishes, get a url to the image on storage
                    imageRef.downloadURL(completion: { (url, error) in
                        // save the url on the database
                        self.db.child("pictures").child(name).setValue(["url": url?.absoluteURL.absoluteString])
                    })
                    
                })
                // start uploading
                uploadTask.resume()
            }
        }
    }

    @IBAction func takePictureButtonPressed(_ sender: Any) {
        let alertViewController = UIAlertController(title: "Want to display a pic?", message: "You can either select it or snap it", preferredStyle: .actionSheet)
        let galleryAction = UIAlertAction(title: "Choose from gallery", style: .default, handler: { action in
            self.openGallery()
        })
        let cameraAction = UIAlertAction(title: "Take photo", style: .default, handler: { action in
            self.openCamera()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            print("cancel")
        })
        alertViewController.addAction(cameraAction)
        alertViewController.addAction(galleryAction)
        alertViewController.addAction(cancelAction)
        present(alertViewController, animated: true, completion: nil)
    }
    
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraDevice = .front
            present(picker, animated: true, completion: nil)
        }
    }
    
    func openGallery() {
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }


}
