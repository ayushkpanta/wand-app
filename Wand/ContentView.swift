import SwiftUI
import Network

struct ContentView: View {
    
    @State private var connection: NWConnection?
    @State private var isConnected: Bool = false
    @State private var commandInput: String = ""

    var body: some View {
        VStack {
            Text(isConnected ? "Connected!" : "Connecting to Server...")
                .padding()
            
            if isConnected {
                TextField("Send a command to your terminal:", text: $commandInput, onCommit: sendCommand)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.default)
            }
            
            Button("Send") {
                sendCommand()
            }
            .padding()
            
        // server stuff
        }
        .onAppear {
            connectToServer()
        }
        .onDisappear {
            disconnectFromServer()
        }
    }
    
    func connectToServer() {
        let host = NWEndpoint.Host("127.0.0.1") // local
        let port = NWEndpoint.Port(integerLiteral: 8080) // same port as server
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        connection?.stateUpdateHandler = { newState in
            switch newState {
                // check for valid connection
            case .ready:
                isConnected = true
                print("Connected to the server!")
            case .failed(let error):
                print("Failed to connect: \(error)")
                isConnected = false
            case .cancelled:
                print("Connection cancelled")
                isConnected = false
            default:
                break
            }
        }
        
        connection?.start(queue: .main)
    }
    
    func sendCommand() {
        guard let connection = connection, isConnected, !commandInput.isEmpty else { return }
        
        // utf encode messag efor valid sending
        let command = commandInput.data(using: .utf8)!
        connection.send(content: command, completion: .contentProcessed({ error in
            
            // check errors in sending
            if let error = error {
                print("Failed to send message: \(error)")
            } else {
                print("Message sent: \(commandInput)")
                commandInput = ""
            }
        }))
    }
    
    func disconnectFromServer() {
        connection?.cancel()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
