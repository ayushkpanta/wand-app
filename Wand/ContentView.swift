import SwiftUI
import Network

// Main view of the application
struct ContentView: View {
    // State variables to manage connection status and user input
    @State private var isConnected: Bool = false
    @State private var commandInput: String = ""
    @State private var serverResponse: String = ""
    @State private var connection: NWConnection?

    var body: some View {
        NavigationView {
            VStack {
                // Show terminal view if connected, otherwise show landing view
                if isConnected {
                    TerminalView(
                        commandInput: $commandInput,
                        serverResponse: $serverResponse,
                        sendCommand: sendCommand
                    )
                } else {
                    LandingView(connectAction: connectToServer)
                }
            }
        }
        .onDisappear {
            disconnectFromServer() // Clean up connection when the view disappears
        }
    }

    // Function to connect to the remote server
    func connectToServer() {
        // Specify the server IP address and port number
        let host = NWEndpoint.Host("192.168.4.22") // Server IP
        let port = NWEndpoint.Port(integerLiteral: 8080) // Port number
        
        // Create a connection to the server
        connection = NWConnection(host: host, port: port, using: .tcp)
        connection?.stateUpdateHandler = { newState in
            // Update the connection state
            switch newState {
            case .ready:
                isConnected = true // Connected successfully
                startReceiving() // Start receiving data from the server
            case .failed(let error):
                print("Failed to connect: \(error)") // Log error
                isConnected = false
            case .cancelled:
                print("Connection cancelled") // Log cancellation
                isConnected = false
            default:
                break
            }
        }
        
        // Start the connection
        connection?.start(queue: .main)
    }
    
    // Function to receive data from the server
    func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data = data, let response = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    serverResponse += response // Append the server response
                }
            }
            // Handle completion or errors
            if isComplete {
                disconnectFromServer() // Disconnect if complete
            } else if let error = error {
                print("Error receiving data: \(error)") // Log receiving error
            } else {
                startReceiving() // Continue receiving
            }
        }
    }
    
    // Function to send commands to the server
    func sendCommand() {
        guard let connection = connection, isConnected, !commandInput.isEmpty else { return }
        
        // Prepare the command for sending
        let command = commandInput.data(using: .utf8)!
        connection.send(content: command, completion: .contentProcessed({ error in
            if let error = error {
                print("Failed to send message: \(error)") // Log sending error
            } else {
                DispatchQueue.main.async {
                    // Display the command in server response
                    serverResponse += "\n$ \(commandInput)\n"
                    commandInput = "" // Clear input after sending
                }
            }
        }))
    }
    
    // Function to disconnect from the server
    func disconnectFromServer() {
        connection?.cancel() // Cancel the connection
    }
}

// Landing view displayed before connection
struct LandingView: View {
    var connectAction: () -> Void // Closure to handle connect action
    
    var body: some View {
        VStack {
            Text("Landing Screen")
                .font(.title) // Set title font size
                .padding()
            
            // Connect button
            Button("Connect") {
                connectAction() // Call connect action
            }
            .padding()
            .background(Color.blue) // Button background color
            .foregroundColor(.white) // Button text color
            .cornerRadius(8) // Rounded corners
        }
    }
}

// Terminal view displayed after connection
struct TerminalView: View {
    @Binding var commandInput: String // Binding for command input
    @Binding var serverResponse: String // Binding for server response
    var sendCommand: () -> Void // Closure to handle command sending

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    // Display server responses
                    Text(serverResponse)
                        .font(.system(size: 14, design: .monospaced)) // Set font size for response
                        .padding()
                    
                    HStack {
                        Text("$") // Terminal prompt
                            .font(.system(size: 14, design: .monospaced)) // Set font size for prompt
                        TextField("Enter command", text: $commandInput, onCommit: {
                            sendCommand() // Send command when return is pressed
                        })
                        .textFieldStyle(PlainTextFieldStyle()) // Plain text field style
                        .font(.system(size: 14, design: .monospaced)) // Set font size for input
                        .autocapitalization(.none) // Disable autocapitalization
                        .disableAutocorrection(true) // Disable autocorrection
                        .frame(maxWidth: .infinity) // Expand text field to fill space
                    }
                    .padding()
                }
            }
            .background(Color.black) // Background color for terminal view
            .foregroundColor(Color.white) // Text color
        }
    }
}

// Preview for the main content view
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
