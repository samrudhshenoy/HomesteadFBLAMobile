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

    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var takePhoto: UIButton!
    @IBOutlet weak var inputPoints: UIButton!
    @State private var isShowingScanner = false
    
    var db: Firestore!
    var imagePicker: UIImagePickerController!


    enum ImageSource {
        case photoLibrary
        case camera
    }
    
      // VIEW DID LOAD
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // [START setup]
            let settings = FirestoreSettings()

            Firestore.firestore().settings = settings
            // [END setup]
            db = Firestore.firestore()
            
            if (takePhoto != nil) {
                takePhoto.layer.cornerRadius = 25
                takePhoto.layer.masksToBounds = false
                takePhoto.layer.shadowColor = UIColor.lightGray.cgColor
                takePhoto.layer.shadowOffset = CGSize(width: 1, height: 2)
                takePhoto.layer.shadowRadius = 1.5
                takePhoto.layer.shadowOpacity = 0.8
            }

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
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                selectImageFrom(.photoLibrary)
                return
            }
            selectImageFrom(.camera)
        }

        // Open Camera
        func selectImageFrom(_ source: ImageSource){
            var success = true
            let errorAlert = UIAlertController(title: "Error", message: "Your camera is not accessible, please try again or ask an officer for assistance", preferredStyle: UIAlertController.Style.alert)
            let done = UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default, handler: { action in })
            errorAlert.addAction(done)
            imagePicker =  UIImagePickerController()
            imagePicker.delegate = self
            
            switch source {
            case .camera:
                imagePicker.sourceType = .camera
            case .photoLibrary:
                success = false
            }
            
            if success == true {
                present(imagePicker, animated: true, completion: nil)
            }
            else {
                present(imagePicker, animated: true, completion: {})
            }
        }
        

        // ReadQRCode and input points
        @IBAction func inputPts (_ sender: AnyObject) {
            
            var pointsCode = "s"
            
            if let features = detectQRCode(img.image), !features.isEmpty{
                for case let row as CIQRCodeFeature in features{
                    pointsCode = row.messageString ?? "empty"
                }
            }
            
            // 0-1: Points
            // 2-3: Date
            // 4-5: Month
            // 6-7: Year
            // 8- : Name of event
            
            
            if (pointsCode == "empty") {
                let errorAlert = UIAlertController(title: "Code not Recognized", message: "Retake image or ask an officer for help", preferredStyle: UIAlertController.Style.alert)
                let done = UIAlertAction(title: "Great!", style: UIAlertAction.Style.default, handler: { action in })
                errorAlert.addAction(done)
                present(errorAlert, animated: true, completion: nil)
            }
            
            else {
                
                print(pointsCode)
                
                var email = ""
                let user = Auth.auth().currentUser
                if let user = user {
                    email = user.email!
                }
                
                // Add new attendee to event list
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
                
                let errorAlert = UIAlertController(title: "Points Inputted!", message: "", preferredStyle: UIAlertController.Style.alert)
                let done = UIAlertAction(title: "Great!", style: UIAlertAction.Style.default, handler: { action in })
                errorAlert.addAction(done)
                present(errorAlert, animated: true, completion: {})

            }
            
        }
        
        func detectQRCode(_ image: UIImage?) -> [CIFeature]? {
            if let image = image, let ciImage = CIImage.init(image: image){
                var options: [String: Any]
                let context = CIContext()
                options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
                let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
                if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)){
                    options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
                } else {
                    options = [CIDetectorImageOrientation: 1]
                }
                let features = qrDetector?.features(in: ciImage, options: options)
                
                return features

            }
            return nil
        }
        
        
        func showAlertWith(title: String, message: String){
            let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
    
        @IBAction func rewindToHome (sender: UIBarButtonItem) {
            dismiss(animated: true, completion: nil)
        }
        
    }

    extension ScanViewController {

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
            imagePicker.dismiss(animated: true, completion: nil)
            guard let selectedImage = info[.originalImage] as? UIImage else {
                print("Image not found!")
                return
            }
            img.image = selectedImage
        }
    }

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
