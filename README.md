# cleanup-ai

## Inspiration
Our objective was to create a mobile application for the "Best Sustainability Hack sponsored by Avanade" category. As we have been recently acquainted with mobile application development and excited about the potential of image recognition and artificial intelligence, we decided to incorporate these technologies into our iOS app. As young adults, we often face challenges when it comes to proper waste disposal and recycling. To address this issue, we created CleanUp.ai - an app that allows individuals to accurately sort their trash and promote sustainable waste management practices.
 
## What it does

CleanUp.ai is a dynamic and interactive iOS app designed to facilitate efficient waste sorting, and each of these features helps users sort through their trash and improve their waste sorting knowledge and habits through various interactive and engaging ways.

Image Recognition: Users can take a photo or select an image from their gallery, and the app will identify the object in the image using the MobileNetV2 machine learning model. This will be sent to OpenAI’s GPT API which will determine if the object belongs in the recycling, garbage, or compost bin.

Location-based Information: As many cities have different rules, it was essential to incorporate this feature. The app uses the user's location to provide waste sorting information specific to their city and province or state.

Display Saved Responses: Users can view their previously saved responses for garbage, recycling, and compost categories. This can be cleared by the user

Quiz: Users are presented with a random item and asked to decide whether it belongs in garbage, recycling, or compost. The item is generated using OpenAI's GPT engine, ensuring a unique and challenging experience each time.

Personal Stats: Users have the option to view their stats, which include the number of questions they've answered and how many of their answers were correct. Depending on their level of accuracy, they can earn one of three badges: Recycling Rookie, Green Guardian, or Sustainability Superstar.

.


## How we built it

This app was designed on Figma and later recreated on xCode with Swift and Storyboards. The application uses a variety of frameworks and tools for its various features.

UIKit: A core framework for building graphical, event-driven user interfaces for iOS, tvOS, and watchOS apps.

Vision: A framework used for detecting and recognizing text, faces, barcodes, and other features in images. Vision is used to analyze images using the Core ML model.

CoreML: A framework for integrating machine learning models into apps. It is used in this code to load the MobileNetV2 model and perform image classification.

CoreLocation: A framework for working with location and geolocation data. In this code, it is used to obtain the user's current location and reverse geocode the location to get the city and province or state

OpenAI: An interface to interact with OpenAI's powerful language models, such as GPT-3, to generate human-like text based on given prompts

## Challenges we ran into

In developing this multifaceted project, integrating several features into a single application posed some challenges. The setup and prompt returned by the OpenAI API were at times problematic. Additionally, the image classification model occasionally proved less than accurate, leading to further issues.

## Accomplishments that we're proud of

We are proud to create a relevant, modern, and useful application for individuals to use. As it is both technical and visually appealing, we are happy with the outcome. The design of the actual application is very close to our original concept.

## What we learned

We learned to use various frameworks and how to create a mobile application in a short period of time. Although one of us has previously dealt with the OpenAI API in a group setting, this is the first time implementing it ourselves. 

