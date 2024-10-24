//
//  ContentView.swift
//  testRun
//
//  Created by Dhrithi Guntaka on 10/17/24.
//

import SwiftUI
import GoogleGenerativeAI

struct ContentView: View {
    @State private var recognizedText = "Tap button to start scanning."
    @State private var showingScanningView = false
    @State private var isProcessing = false
    @State private var aiResponse = ""
    let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)

    @State private var userPrompt = ""
    @State private var scanStatusMessage = ""

    @State private var showSummary = false
    @State private var showPracticeQuestions = false
    @State private var showImportantVocabulary = false
    @State private var includeAdditionalResources = false

    var body: some View {
        VStack(spacing: 16) {
            VStack {
                Image("epistemicLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 600, height: 85)
                    .border(Color.black, width: 2)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
            }

            VStack {
                DisclosureGroup("Select Study Material Options") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Summary", isOn: $showSummary)
                        Toggle("Practice Questions with Answers", isOn: $showPracticeQuestions)
                        Toggle("Important Vocabulary", isOn: $showImportantVocabulary)
                        Toggle("Include Additional Resources (e.g., videos, articles)", isOn: $includeAdditionalResources)
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 10)

            if isProcessing {
                ProgressView("Processing...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }

            ScrollView {
                VStack(alignment: .center, spacing: 8) {
                    Text("Generated Study Material:")
                        .font(.headline)
                        .padding(.top, 20)

                    Text(aiResponse.isEmpty ? "No response yet." : aiResponse)
                        .padding()
                        .background(Color.green.opacity(0.7))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }

            Spacer()

            TextField("Enter a topic or use scanned text", text: $userPrompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(.black)
                .padding(.horizontal)
                .padding(.bottom, 8)

            Button("Submit Topic") {
                sendRequestToGemini(request: userPrompt)
            }
            .padding(.vertical, 2)

            Button("Start Scanning Image") {
                showingScanningView.toggle()
            }
            .sheet(isPresented: $showingScanningView) {
                ScanDocumentView(recognizedText: $recognizedText)
            }
            .padding(.vertical, 2)

            Button("Clear") {
                clearResponse()
            }
            .foregroundColor(.red)
            .padding(.vertical, 2)
        }
        .padding()
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("RecognizedText"), object: nil, queue: .main) { notification in
                if let recognized = notification.object as? String {
                    recognizedText = recognized
                    userPrompt = recognized
                    sendRequestToGemini(request: recognized)
                }
            }
        }
        .foregroundColor(.white)
        .background(Color.black.ignoresSafeArea())
    }

    func clearResponse() {
        aiResponse = ""
        isProcessing = false
        userPrompt = ""
        recognizedText = ""
        showSummary = false
        showPracticeQuestions = false
        showImportantVocabulary = false
        includeAdditionalResources = false
    }

    func sendRequestToGemini(request: String) {
        if request.isEmpty {
            return
        }

        isProcessing = true
        aiResponse = ""

        var promptBase = "Please provide the following information for the topic: '\(request)'.\n\n"

        if showSummary {
            promptBase += "- A detailed summary with additional insights and notes.\n"
        }
        
        if showPracticeQuestions {
            promptBase += "- A set of practice questions with answers provided directly below each question.\n"
        }
        
        if showImportantVocabulary {
            promptBase += "- A list of important vocabulary terms with definitions.\n"
        }

        if includeAdditionalResources {
            promptBase += "- Include links to relevant articles, videos, or resources for further learning.\n"
        }

        if promptBase == "Please provide the following information for the topic: '\(request)'.\n\n" {
            aiResponse = "Please select at least one category to generate a response."
            isProcessing = false
            return
        }

        let safePromptBase = promptBase

        Task {
            do {
                let response = try await model.generateContent(safePromptBase)
                guard let generatedText = response.text else {
                    aiResponse = "Sorry, I could not process that.\nPlease try again."
                    return
                }

                aiResponse = generatedText
                isProcessing = false
            } catch {
                aiResponse = "Something went wrong!\n\(error.localizedDescription)"
                isProcessing = false
            }
        }
    }
}
