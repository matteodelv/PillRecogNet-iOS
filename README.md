# PillRecogNet iOS App
This is Part 2 of my Undergraduate Thesis Project @ UniBo: an iOS application that uses Metal Performance Shaders to run a convolutional neural network on the GPU of capable devices. The ConvNet the app will run is **PillRecogNet**, trained and fine tuned to recognize pill images, as described in [Part 1](http://github.com/matteodelv/PillRecogNet).  
  
The main goal of this application is to allow inference through the GPU and then save classifications thanks to Core Data.  
The core is ```PillRecogNet.swift``` which is the file that implements the entire neural network; ```Preprocessing.metal``` is a custom Metal Shader necessary to apply mean RGB value subtraction to image values, since this preprocessing has been applied during training; ```PillLabelManager.swift```, instead, is a generic implementation used to manage class labels the net will recognize. This file uses ```pillLabels.txt``` which has to be edited accordingly to your dataset.

### Usage on a custom dataset
The application can easily be used with a custom dataset, provided that the neural network has been retrained and fine tuned as described in [Part 1](http://github.com/matteodelv/PillRecogNet). In fact, this repo won't work *AS IS*: parameters for the net must be exported before running the application.

1. Clone both [Part 1](http://github.com/matteodelv/PillRecogNet) and [Part 2](http://github.com/matteodelv/PillRecogNet-iOS) repos.
2. If you plan to use a custom dataset, follow the instructions to retrain the network; otherwise, download ```fine-tuned-model.h5``` from [Part 1 Releases](https://github.com/matteodelv/PillRecogNet/releases) page.
3. Use the script ```weights-converter.py``` to convert and export the parameters.
4. Open this Xcode project, add these binary files and make sure they are copied in the app bundle in Build Phases settings.
5. Change Project settings to provide your Signing Team.
6. If you retrained the network on a custom dataset, open ```PillLabelManager.swift``` and edit the ```classesCount``` variable to reflect the number of classes in your dataset.
7. Open and edit ```pillLabels.txt``` to provide labels for your classes. This file MUST follow the format ```index|label```, where ```index``` is a number starting from 0 and ```label``` is the class name that will be displayed in the app.  
**NOTE:** If you retrained the network, the correspondence between indexes and labels depends on the training; this information is printed on the terminal during fine tuning or model evaluation. Otherwise, if you just want to use the fine tuned example, these labels can be downloaded from [Releases](https://github.com/matteodelv/PillRecogNet-iOS/releases) page of this repo.
8. Now you should be able to build and run the application.

### Requirements
* Xcode 9.0+
* iOS 10.0+
* A real capable[^1] device (Metal Performance Shaders won't run/work on the Simulator)


[^1]: As described in Metal Performance Shaders documentation, to run a convolutional neural network on the GPU requires devices belonging to these categories: ```GPU Family 2 v3```, ```GPU Family 3 v2```, ```GPU Family 4 v1```, or superior, which means devices with at least the Apple A8 chip (iPhone 6/6+ or later, iPad Air 2 or later, iPad mini 4, iPod touch 6G).