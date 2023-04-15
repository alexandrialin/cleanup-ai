import UIKit

class QuizViewController: UIViewController {
    
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var correctLabel: UILabel!
    @IBOutlet weak var correctSymbol: UIImageView!
    @IBOutlet weak var incorrectSymbol: UIImageView!
    @IBOutlet weak var recycleButton: UIButton!
    @IBOutlet weak var garbageButton: UIButton!
    @IBOutlet weak var compostButton: UIButton!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var correctCountLabel: UILabel!
    @IBOutlet weak var totalCountLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var l1: UIImageView!
    @IBOutlet weak var l2: UIImageView!
    @IBOutlet weak var l3: UIImageView!


    
    var latestResponse: String = ""
    private var previousAnswers: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabelsAndTitle()
        let prompt = "choose a random item that goes into either the garbage, recycling, or compost. only return the one word. dont add any punctuation or any notes. be unique with your answer. don't return the same answer as the last 10 answers"
        
        generateResponse(prompt: prompt) { response in
            print("Generated response: \(response)")
            self.latestResponse = response
            DispatchQueue.main.async {
                self.answerLabel.text = "Which bin should \(response) go in?"
                        }
        }
    }

    func generateResponse(prompt: String, completion: @escaping (String) -> Void) {
        // Replace with your API key
        let apiKey = "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"
        
        let url = URL(string: "https://api.openai.com/v1/engines/text-davinci-002/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let data: [String: Any] = [
            "prompt": prompt,
            "max_tokens": 10,
            "temperature": 0.7,
            "top_p": 1
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])
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
                            completion(response)
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
                            self.generateResponse(prompt: prompt, completion: completion)
                        }
                    } else {
                        print("HTTP error: \(response.debugDescription)")
                    }
                }
            }
        }
        
        task.resume()
    }
    @IBAction func navigateToViewController(_ sender: Any) {
        performSegue(withIdentifier: "toViewController", sender: self)
    }
    @IBAction func navigateToHomeController(_ sender: Any) {
        performSegue(withIdentifier: "toHomeController", sender: self)
    }
    @IBAction func nextItem(_ sender: Any) {
        generateNewResponse()
    }

    func generateNewResponse() {
        let prompt = "choose a random item that goes into either the garbage, recycling, or compost. only return the one word. dont add any punctuation or any notes. be unique with your answer. don't return the same answer as the last 10 answers"
        
        generateResponse(prompt: prompt) { response in
            print("Generated response: \(response)")
            self.latestResponse = response
            DispatchQueue.main.async {
                self.answerLabel.text = "Which bin should \(response) go in?"
                self.correctLabel.text = ""
                self.correctSymbol.isHidden = true
                self.incorrectSymbol.isHidden = true
                self.recycleButton.isHidden = false
                self.garbageButton.isHidden = false
                self.compostButton.isHidden = false
                        }
        }
    }
    
    func isRecyclable(item: String, completion: @escaping (Bool) -> Void) {
        let prompt = "Does \(item) go into the recycling? If it goes in garbage or compost answer false, must be one of the three. Only respond with true or false, nothing else. Please triple check."

        generateResponse(prompt: prompt) { response in
            let recyclable = response.lowercased() == "true"
            completion(recyclable)
        }
    }

    func isGarbage(item: String, completion: @escaping (Bool) -> Void) {
        let prompt = "Does \(item) go into the garbage? If it goes in recycling or compost answer false, must be one of the three. Only respond with true or false, nothing else. Please triple check."

        generateResponse(prompt: prompt) { response in
            let garbage = response.lowercased() == "true"
            completion(garbage)
        }
    }
    func isCompost(item: String, completion: @escaping (Bool) -> Void) {
        let prompt = "Does \(item) go into the compost? If it goes in recycling or garbage answer false, must be one of the three. Only respond with true or false, nothing else. Please triple check."

        generateResponse(prompt: prompt) { response in
            let compostable = response.lowercased() == "true"
            completion(compostable)
        }
    }
    
    @IBAction func checkRecyclability(_ sender: Any) {
        let (correctAnswers, totalAnswers) = loadUserDefaults()
        isRecyclable(item: latestResponse) { recyclable in
            print("Is \(self.latestResponse) recyclable? \(recyclable)")
            DispatchQueue.main.async {
                self.compostButton.isHidden = true
                self.garbageButton.isHidden = true
                if(recyclable)
                {
                    self.correctLabel.text = "You are Correct!"
                    self.correctSymbol.isHidden = false
                }
                else{
                    self.correctLabel.text = "You are Incorrect!"
                    self.incorrectSymbol.isHidden = false
                }
                let newTotalAnswers = totalAnswers + 1
                let newCorrectAnswers = correctAnswers + (recyclable ? 1 : 0)
                self.saveUserDefaults(correctAnswers: newCorrectAnswers, totalAnswers: newTotalAnswers)
                self.updateLabelsAndTitle()
            }
        }
    }
    @IBAction func checkGarbage(_ sender: Any) {
        let (correctAnswers, totalAnswers) = loadUserDefaults()
        isGarbage(item: latestResponse) { garbage in
            print("Is \(self.latestResponse) garbage? \(garbage)")
            DispatchQueue.main.async {
                self.recycleButton.isHidden = true
                self.compostButton.isHidden = true
                if(garbage)
                {
                    self.correctLabel.text = "You are Correct!"
                    self.correctSymbol.isHidden = false
                }
                else{
                    self.correctLabel.text = "You are Incorrect!"
                    self.incorrectSymbol.isHidden = false
                }
                let newTotalAnswers = totalAnswers + 1
                let newCorrectAnswers = correctAnswers + (garbage ? 1 : 0)
                self.saveUserDefaults(correctAnswers: newCorrectAnswers, totalAnswers: newTotalAnswers)
                self.updateLabelsAndTitle()
            }
        
        }
    }
    @IBAction func checkCompost(_ sender: Any) {
        let (correctAnswers, totalAnswers) = loadUserDefaults()
        isCompost(item: latestResponse) { compostable in
            print("Is \(self.latestResponse) compostable? \(compostable)")
            DispatchQueue.main.async {
                self.recycleButton.isHidden = true
                self.garbageButton.isHidden = true
                if(compostable)
                {
                    self.correctLabel.text = "You are Correct!"
                    self.correctSymbol.isHidden = false
                }
                else{
                    self.correctLabel.text = "You are Incorrect!"
                    self.incorrectSymbol.isHidden = false
                }
                let newTotalAnswers = totalAnswers + 1
                let newCorrectAnswers = correctAnswers + (compostable ? 1 : 0)
                self.saveUserDefaults(correctAnswers: newCorrectAnswers, totalAnswers: newTotalAnswers)
                self.updateLabelsAndTitle()
            }
        }
    }
    
    @IBAction func closePhoto(_ sender: Any) {
        self.popupView.isHidden = true
    }
    @IBAction func openPhoto(_ sender: Any) {
        self.popupView.isHidden = false
    }
    func saveUserDefaults(correctAnswers: Int, totalAnswers: Int) {
        UserDefaults.standard.set(correctAnswers, forKey: "correctAnswers")
        UserDefaults.standard.set(totalAnswers, forKey: "totalAnswers")
    }

    func loadUserDefaults() -> (correctAnswers: Int, totalAnswers: Int) {
        let correctAnswers = UserDefaults.standard.integer(forKey: "correctAnswers")
        let totalAnswers = UserDefaults.standard.integer(forKey: "totalAnswers")
        return (correctAnswers, totalAnswers)
    }
    func updateLabelsAndTitle() {
        let (correctAnswers, totalAnswers) = loadUserDefaults()
        
        correctCountLabel.text = "\(correctAnswers)"
        totalCountLabel.text = "\(totalAnswers)"
        
        switch correctAnswers {
        case 0..<10:
            titleLabel.text = "Recycling Rookie"
            self.l1.isHidden = false
            self.l2.isHidden = true
            self.l3.isHidden = true
        case 10..<21:
            titleLabel.text = "Green Guardian"
            self.l1.isHidden = true
            self.l2.isHidden = false
            self.l3.isHidden = true
        default:
            titleLabel.text = "Sustainability Superstar"
            self.l1.isHidden = true
            self.l2.isHidden = true
            self.l3.isHidden = false
        }
    }




}
