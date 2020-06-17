//
//  ScanViewController.swift
//  Homestead FBLA
//
//  Created by Samrudh Shenoy on 4/22/20.
//  Copyright © 2020 Samrudh Shenoy. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import AVKit
import SwiftUI
import CodeScanner

class ScanViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    // Declares all UI elements
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var takePhoto: UIButton!
    @IBOutlet weak var inputPoints: UIButton!
    @State private var isShowingScanner = false
    
    // Declares instance of database and photo library picker
    var db: Firestore!
    var imagePicker: UIImagePickerController!

    // Whether the photo will be taken from the camera or chosen from library
    enum ImageSource {
        case photoLibrary
        case camera
    }
    
      // VIEW DID LOAD
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // [START db setup]
            let settings = FirestoreSettings()

            Firestore.firestore().settings = settings
            // [END db setup]
            db = Firestore.firestore()
            
            // Verifies whether button exists before customizing it
            if (takePhoto != nil) {
                takePhoto.layer.cornerRadius = 25
                takePhoto.layer.masksToBounds = false
                takePhoto.layer.shadowColor = UIColor.lightGray.cgColor
                takePhoto.layer.shadowOffset = CGSize(width: 1, height: 2)
                takePhoto.layer.shadowRadius = 1.5
                takePhoto.layer.shadowOpacity = 0.8
            }

            // Verifies whether button exists before customizing it
            if (inputPoints != nil) {
                inputPoints.layer.cornerRadius = 25
                inputPoints.layer.masksToBounds = false
                inputPoints.layer.shadowColor = UIColor.lightGray.cgColor
                inputPoints.layer.shadowOffset = CGSize(width: 1, height: 2)
                inputPoints.layer.shadowRadius = 1.5
                inputPoints.layer.shadowOpacity = 0.8
            }


        }

        
        // Photo button clicked
        @IBAction func takePic (_ sender: UIButton) {
            // If camera is not available, choose image from library
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                selectImageFrom(.photoLibrary)
                return
            }
            // Otherwise, click picture from camera
            selectImageFrom(.camera)
        }

        // Open Camera
        func selectImageFrom(_ source: ImageSource){
            // Successful trigger of photo picking method
            var success = true
            // Temporary error alert (not currently in use)
            let errorAlert = UIAlertController(title: "Error", message: "Your camera is not accessible, please try again or ask an officer for assistance", preferredStyle: UIAlertController.Style.alert)
            let done = UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default, handler: { action in })
            errorAlert.addAction(done)
            // Setup for choosing pic
            imagePicker =  UIImagePickerController()
            imagePicker.delegate = self
            
            // Determines which source was chosen
            switch source {
            case .camera:
                imagePicker.sourceType = .camera
            case .photoLibrary:
                success = false
            }
            
            // Opens camera if available (camera not tested so currently opens photo library)
            if success == true {
                present(imagePicker, animated: true, completion: nil)
            }
            // Opens photo library if camera is not available
            else {
                present(imagePicker, animated: true, completion: {})
            }
        }
        

        // Reads QRCode and inputs points
        @IBAction func inputPts (_ sender: AnyObject) {
            // Arbitrary value as declaration
            var pointsCode = "s"
            
            // Checks if QR code has actual content
            if let features = detectQRCode(img.image), !features.isEmpty{
                for case let row as CIQRCodeFeature in features {
                    // Retrieves QR code value and sets pointsCode equal to it
                    pointsCode = row.messageString ?? "empty"
                }
            }
            
            
            // Pops up alert if code is not recognized
            if (pointsCode == "empty") {
                let errorAlert = UIAlertController(title: "Code not Recognized", message: "Retake image or ask an officer for help", preferredStyle: UIAlertController.Style.alert)
                let done = UIAlertAction(title: "Okay!", style: UIAlertAction.Style.default, handler: { action in })
                errorAlert.addAction(done)
                present(errorAlert, animated: true, completion: nil)
            }
            
            // Analyzes code if it has content
            else {
                
                print(pointsCode)
                
                // Retrieves current user's email
                var email = ""
                let user = Auth.auth().currentUser
                if let user = user {
                    email = user.email!
                }
                
                // Adds user as attendee to event list in database
                let event = db.collection("activity points").document(pointsCode)
                event.updateData([
                    "Attendees": FieldValue.arrayUnion([email])
                ])
                
//                var eventName = ""
//                var numPoints = 0
//                event.getDocument { (document, error) in
//                    if let document = document, document.exists {
//                        eventName = document.get("event") as! String
//                        numPoints = document.get("points") as! Int
//                    } else {
//                        print("Document does not exist")
//                    }
//                }
                
                // Pop up success message
                let errorAlert = UIAlertController(title: "Points Inputted!", message: "", preferredStyle: UIAlertController.Style.alert)
                let done = UIAlertAction(title: "Great!", style: UIAlertAction.Style.default, handler: { action in })
                errorAlert.addAction(done)
                present(errorAlert, animated: true, completion: {})

            }
            
        }
        
        // Reads QR code and returns its content
        func detectQRCode(_ image: UIImage?) -> [CIFeature]? {
            // Creates new image based on UIImage passed in
            if let image = image, let ciImage = CIImage.init(image: image){
                var options: [String: Any]
                let context = CIContext()
                options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
                // Creates new QR code reader
                let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
                // Whether QR code can be read in as a String
                if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)){
                    options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
                } else {
                    options = [CIDetectorImageOrientation: 1]
                }
                // Creates features variable containing content of QR code
                let features = qrDetector?.features(in: ciImage, options: options)
                // Returns features variable
                return features

            }
            // Default return if image translation fails
            return nil
        }
        
        // Shows a popup alert with a message
        func showAlertWith(title: String, message: String){
            let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
        // Returns to home screen
        @IBAction func rewindToHome (sender: UIBarButtonItem) {
            dismiss(animated: true, completion: nil)
        }
        
    }

    extension ScanViewController {

        // Mechanism for choosing image from library
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
            imagePicker.dismiss(animated: true, completion: nil)
            guard let selectedImage = info[.originalImage] as? UIImage else {
                print("Image not found!")
                return
            }
            img.image = selectedImage
        }
    }

// Methods for parsing Strings (for simplicity since Strings in Swift are wack)
    extension String {
        subscript(_ range: CountableRange<Int>) -> String {
            let start = index(startIndex, offsetBy: max(0, range.lowerBound))
            let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                                 range.upperBound - range.lowerBound))
            return String(self[start..<end])
        }

        subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
            let start = index(startIndex, offsetBy: max(0, range.lowerBound))
             return String(self[start...])
        }
    }

    extension StringProtocol {
        subscript(_ offset: Int)                     -> Element     { self[index(startIndex, offsetBy: offset)] }
        subscript(_ range: Range<Int>)               -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }
        subscript(_ range: ClosedRange<Int>)         -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }
        subscript(_ range: PartialRangeThrough<Int>) -> SubSequence { prefix(range.upperBound.advanced(by: 1)) }
        subscript(_ range: PartialRangeUpTo<Int>)    -> SubSequence { prefix(range.upperBound) }
        subscript(_ range: PartialRangeFrom<Int>)    -> SubSequence { suffix(Swift.max(0, count-range.lowerBound)) }
    }

    extension LosslessStringConvertible {
        var string: String { .init(self) }
    }

    extension BidirectionalCollection {
        subscript(safe offset: Int) -> Element? {
            guard !isEmpty, let i = index(startIndex, offsetBy: offset, limitedBy: index(before: endIndex)) else { return nil }
            return self[i]
        }
    }
