import Foundation
import SwiftData

@Observable
class ChatViewModel {
    var messages: [Message] = []
    var isLoading = false
    var errorMessage: String?
    
    private let modelContext: ModelContext
    private var userProfile: UserProfile
    var promises: [Promise]
    
    init(modelContext: ModelContext, profile: UserProfile, promises: [Promise]) {
        self.modelContext = modelContext
        self.userProfile = profile
        self.promises = promises
    }
    
    func updatePromises(_ newPromises: [Promise]) {
        self.promises = newPromises
    }
    
    func sendMessage(_ text: String) async {
        // Add user message (don't persist to database - fresh start each session)
        let userMessage = Message(content: text, isUser: true)
        // Don't insert to modelContext - we're not persisting messages
        messages.append(userMessage)
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Get AI response
            let response = try await AICoachService.sendMessage(
                text,
                conversationHistory: messages,
                userProfile: userProfile,
                currentPromises: promises
            )
            
            // Check if response contains a promise to create
            if let promiseIntent = AICoachService.parsePromiseFromConversation(response) {
                // Check if a promise with the same text was just created (prevent duplicates)
                let existingPromise = promises.first { $0.text == promiseIntent.text && 
                    abs($0.createdAt.timeIntervalSinceNow) < 5 } // Created within last 5 seconds
                if existingPromise != nil {
                    // Still add the AI response as a message
                    let aiMessage = Message(content: response.components(separatedBy: "PROMISE_CREATE").first ?? response, isUser: false)
                    messages.append(aiMessage)
                    isLoading = false
                    return
                }
                
                // Create the promise with custom frequency using the time from the conversation
                let promise = Promise(
                    text: promiseIntent.text,
                    due: promiseIntent.due,
                    context: promiseIntent.context
                )
                
                // Extract the time from the due date (set by AI based on conversation)
                // Use the hour and minute from promiseIntent.due for the notification time
                let calendar = Calendar.current
                let dueComponents = calendar.dateComponents([.hour, .minute], from: promiseIntent.due)
                let notificationTime = calendar.date(bySettingHour: dueComponents.hour ?? 9, 
                                                     minute: dueComponents.minute ?? 0, 
                                                     second: 0, 
                                                     of: Date()) ?? DateUtils.defaultTime()
                
                // Set custom frequency using the time from the conversation
                promise.customDailyTimes = [notificationTime]
                
                // For daily promises, recalculate the due date to the next occurrence
                // This ensures the countdown timer shows the correct time (tomorrow at scheduled time)
                promise.due = DateUtils.calculateNextDueDate(for: promise)
                
                // Generate personalized notification
                let notificationMsg = try await AICoachService.generateNotificationMessage(
                    for: promise,
                    userProfile: userProfile
                )
                promise.notificationMessage = notificationMsg
                
                modelContext.insert(promise)
                
                // Save the context to ensure the promise is persisted with frequency settings
                do {
                    try modelContext.save()
                } catch {
                    // Failed to save promise
                }
                
                // Schedule notification
                // If agent is assigned, pass nil so agent generation happens
                // Otherwise, use the generated notificationMsg
                let messageToUse: String? = promise.notificationAgent != nil ? nil : notificationMsg
                NotificationManager.schedule(for: promise, with: messageToUse, userProfile: userProfile)
                
                // Update profile
                userProfile.totalPromises += 1
                
                // Save profile updates
                do {
                    try modelContext.save()
                } catch {
                    // Failed to save profile
                }
                
                // Add confirmation message (strip out the PROMISE_CREATE command)
                let cleanResponse = response.components(separatedBy: "PROMISE_CREATE").first ?? response
                let confirmationMessage = Message(
                    content: cleanResponse.trimmingCharacters(in: .whitespacesAndNewlines),
                    isUser: false,
                    relatedPromiseId: promise.id
                )
                // Don't persist to database - fresh start each session
                messages.append(confirmationMessage)
            } else {
                // Regular conversation message
                let aiMessage = Message(content: response, isUser: false)
                // Don't persist to database - fresh start each session
                messages.append(aiMessage)
            }
            
        } catch {
            // Provide more specific error messages
            if let aiError = error as? AICoachError {
                switch aiError {
                case .apiError:
                    errorMessage = "Unable to connect to AI service. Please check your internet connection and try again."
                case .parsingError:
                    errorMessage = "Received an unexpected response. Please try rephrasing your message."
                case .invalidResponse:
                    errorMessage = "Invalid response from AI. Please try again."
                }
            } else {
                errorMessage = "I'm having trouble connecting right now. Please try again."
            }
        }
        
        isLoading = false
    }
    
    func loadMessages() {
        // Messages are already in memory from the ViewModel
        // They persist during the app session and only clear on app restart
        // No need to load from database - we keep them in memory
    }
}

// MARK: - Promise Chat View Model
@Observable
class PromiseChatViewModel {
    var messages: [Message] = []
    var isLoading = false
    var errorMessage: String?
    var promiseUpdated = false
    
    var modelContext: ModelContext
    private var userProfile: UserProfile
    // Don't store promise here - we'll pass it as a parameter to applyPromiseEdits
    // This ensures we always modify the correct @Bindable instance
    
    init(promise: Promise, profile: UserProfile, modelContext: ModelContext) {
        self.userProfile = profile
        self.modelContext = modelContext
        // Don't store promise - we'll use the one from the view
        // The promise parameter is only used for initial message setup
        _ = promise.id // Use promise to avoid unused parameter warning
    }
    
    func loadMessages() {
        // Messages are kept in memory during the session
    }
    
    func sendMessage(_ text: String, promise: Promise) async {
        // Add user message
        let userMessage = Message(content: text, isUser: true, relatedPromiseId: promise.id)
        messages.append(userMessage)
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Get AI response focused on notification content editing only
            let response = try await AICoachService.sendNotificationContentMessage(
                text,
                conversationHistory: messages,
                userProfile: userProfile,
                promise: promise
            )
            
            // Check if response contains notification content update
            if let notificationMessage = AICoachService.parseNotificationContentFromConversation(response) {
                // Update the promise's notification message
                promise.notificationMessage = notificationMessage
                
                // Save changes
                do {
                    try modelContext.save()
                } catch {
                    // Failed to save notification message
                }
                
                // Add confirmation message
                let cleanResponse = response.components(separatedBy: "NOTIFICATION_CONTENT").first ?? response
                let confirmationMessage = Message(
                    content: cleanResponse.trimmingCharacters(in: .whitespacesAndNewlines),
                    isUser: false,
                    relatedPromiseId: promise.id
                )
                messages.append(confirmationMessage)
                
                promiseUpdated = true
            } else {
                // Regular conversation message
                let aiMessage = Message(content: response, isUser: false, relatedPromiseId: promise.id)
                messages.append(aiMessage)
            }
            
        } catch {
            if let aiError = error as? AICoachError {
                switch aiError {
                case .apiError:
                    errorMessage = "Unable to connect to AI service. Please check your internet connection and try again."
                case .parsingError:
                    errorMessage = "Received an unexpected response. Please try rephrasing your message."
                case .invalidResponse:
                    errorMessage = "Invalid response from AI. Please try again."
                }
            } else {
                errorMessage = "I'm having trouble connecting right now. Please try again."
            }
        }
        
        isLoading = false
    }
    
}

