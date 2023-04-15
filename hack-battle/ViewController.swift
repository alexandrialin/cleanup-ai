import UIKit
import AVFoundation
import Vision
import CoreML
import Foundation
import CoreLocation



class ViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var responseLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!

    let locationManager = CLLocationManager()


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        } else {
            print("Location services are disabled or not authorized")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationManager.stopUpdatingLocation()
        fetchCityNameAndProvince(from: location)
    }
    func fetchCityNameAndProvince(from location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first, let city = placemark.locality, let provinceOrState = placemark.administrativeArea {
                DispatchQueue.main.async {
                    self?.locationLabel.text = "\(city), \(provinceOrState)"
                    
                    // Re-analyze the image with the city name and province/state
                    if let image = self?.imageView.image {
                        self?.analyzeImage(image: image, cityName: city, provinceOrState: provinceOrState)
                    }
                }
            }
        }
    }


    
    @IBAction func takePictureButtonTapped(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a source", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true, completion: nil)
            } else {
                print("Camera not available")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        imageView.image = selectedImage
        self.popupView.isHidden = false
        
        picker.dismiss(animated: true, completion: nil)
        
        if CLLocationManager.locationServicesEnabled() {
            if let currentLocation = locationManager.location {
                fetchCityNameAndProvince(from: currentLocation)
            } else {
                print("Failed to fetch current location")
                // Handle the case when location is not available
                analyzeImageWithoutLocation(image: selectedImage)
            }
        } else {
            print("Location services are disabled or not authorized")
            // Handle the case when location services are disabled or not authorized
            analyzeImageWithoutLocation(image: selectedImage)
        }
    }

    func analyzeImage(image: UIImage, cityName: String, provinceOrState: String) {
        guard let ciImage = CIImage(image: image) else {
            fatalError("Unable to create a CIImage from UIImage")
        }
        
        let orientationInt32 = Int32(image.imageOrientation.rawValue)
        let inputImage = ciImage.oriented(forExifOrientation: orientationInt32)
        
        guard let modelURL = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodelc"),
              let model = try? MLModel(contentsOf: modelURL),
              let visionModel = try? VNCoreMLModel(for: model) else {
            print("Failed to load MobileNetV2 model")
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            self?.processResults(for: request, error: error, cityName: cityName,provinceOrState: provinceOrState)
        }
        
        let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])
        try? handler.perform([request])
    }

    
    private func processResults(for request: VNRequest, error: Error?, cityName: String, provinceOrState: String) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNClassificationObservation],
               let topResult = results.first {
                let objectName = topResult.identifier
                let prompt = "In \(cityName), \(provinceOrState), does the \(objectName) go into the recycling, garbage, or compost? Answer with only one word lowercase, either 'recycling', 'garbage' or 'compost'. Only say compost if you know for sure its compost. Please triple check."
                self.generateResponse(prompt: prompt, objectName: objectName) { response in
                    print("Generated response: \(response)")
                    DispatchQueue.main.async {
                        self.locationLabel.text = "\(cityName), \(provinceOrState)"
                        self.responseLabel.text = "In \(cityName), \(provinceOrState), you throw the \(objectName) in the \(response)."
                    }
                }
            }
        }
    }


    func generateResponse(prompt: String, objectName: String, completion: @escaping (String) -> Void) {
        // Replace with your API key
        let apiKey = "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"
        
        let url = URL(string: "https://api.openai.com/v1/engines/text-davinci-002/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonBody: [String: Any] = [
            "prompt": prompt,
            "max_tokens": 50, // Set the maximum number of tokens in the response
            "n": 1, // Set the number of completions to generate
            "temperature": 0.7 // Add this line
        ]

        print("Prompt: \(prompt)") // Add this line to print the prompt

        let jsonData = try? JSONSerialization.data(withJSONObject: jsonBody, options: [])
        request.httpBody = jsonData

        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error calling OpenAI API: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    do {
                        let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        print("JSON Result: \(jsonResult ?? [:])")
                        
                        if let choices = jsonResult?["choices"] as? [[String: Any]],
                           let choice = choices.first,
                           let text = choice["text"] as? String {
                            let response = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if response.lowercased() == "recycling" {
                                self.saveResponse(objectName, category: "recycling")
                                completion(response)
                            } else if response.lowercased() == "garbage" {
                                self.saveResponse(objectName, category: "garbage")
                                completion(response)
                            } else if response.lowercased() == "compost" {
                                self.saveResponse(objectName, category: "compost")
                                completion(response)
                            } else {
                                self.saveResponse(objectName, category: "unknown")
                                completion(response)
                            }
                        } else {
                            print("Failed to parse OpenAI API response")
                        }
                    } catch {
                        print("Error parsing JSON: \(error.localizedDescription)")
                    }
                } else {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode data")")
                    if httpResponse.statusCode == 429 {
                        print("Rate limit exceeded. Retrying after 1 second...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.generateResponse(prompt: prompt, objectName: objectName, completion: completion)
                        }
                    } else {
                        print("HTTP error: \(response.debugDescription)")
                    }
                }
            }
        }
        
        task.resume()
    }



    
    func saveResponse(_ response: String, category: String) {
        let defaults = UserDefaults.standard
        
        // Retrieve the appropriate array based on the category
        let key = "savedResponses_\(category)"
        var savedResponses = defaults.array(forKey: key) as? [String] ?? [String]()
        
        // Append the new response to the array
        savedResponses.append(response)
        
        // Save the updated array to UserDefaults
        defaults.set(savedResponses, forKey: key)
    }

    
    func getSavedResponsesString(for category: String) -> String {
        let defaults = UserDefaults.standard
        let key = "savedResponses_\(category)"
        let savedResponses = defaults.array(forKey: key) as? [String] ?? [String]()
        
        return savedResponses.joined(separator: "\n")
    }

    func displaySavedResponses() {
        let garbageResponses = getSavedResponsesString(for: "garbage")
        let recyclingResponses = getSavedResponsesString(for: "recycling")
        let compostResponses = getSavedResponsesString(for: "compost")
        
        print("Garbage Responses:\n\(garbageResponses)\n")
        print("Recycling Responses:\n\(recyclingResponses)\n")
        print("Compost Responses:\n\(compostResponses)\n")
    }
    @IBAction func displayResponsesButton(_ sender: Any) {
        displaySavedResponses()
    }

    
    func analyzeImageWithoutLocation(image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            fatalError("Unable to create a CIImage from UIImage")
        }
        
        let orientationInt32 = Int32(image.imageOrientation.rawValue)
        let inputImage = ciImage.oriented(forExifOrientation: orientationInt32)
        
        guard let modelURL = Bundle.main.url(forResource: "MobileNetV2", withExtension: "mlmodelc"),
              let model = try? MLModel(contentsOf: modelURL),
              let visionModel = try? VNCoreMLModel(for: model) else {
            print("Failed to load MobileNetV2 model")
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            self?.processResultsWithoutLocation(for: request, error: error)
        }
        
        let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])
        try? handler.perform([request])
    }

    private func processResultsWithoutLocation(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNClassificationObservation],
               let topResult = results.first {
                let objectName = topResult.identifier
                let prompt = "Does the \(objectName) go into the recycling, garbage, or compost? Answer with only one word lowercase, either 'recycling', 'garbage' or 'compost'. Only say compost if you know for sure its compost. Please triple check"
                self.generateResponse(prompt: prompt, objectName: objectName) { response in
                    print("Generated response: \(response)")
                    DispatchQueue.main.async {
                        self.responseLabel.text = "Throw the \(objectName) in the \(response)."
                    }
                }
            }
        }
    }

    
    @IBAction func closePhoto(_ sender: Any) {
        self.popupView.isHidden = true
    }
    
    @IBAction func navigateToHomeController(_ sender: Any) {
        performSegue(withIdentifier: "toHomeController", sender: self)
    }
    @IBAction func navigateToQuizController(_ sender: Any) {
        performSegue(withIdentifier: "toQuizController", sender: self)
    }


}

