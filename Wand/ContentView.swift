import SwiftUI
import Network

struct ContentView: View {
    @State private var isConnected: Bool = false
    @State private var commandInput: String = ""
    @State private var serverResponse: String = ""
    @State private var connection: NWConnection?

    var body: some View {
        NavigationView {
            VStack {
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
            disconnectFromServer()
        }
    }

    func connectToServer() {
//        let host = NWEndpoint.Host("127.0.0.1") // local
        let host = NWEndpoint.Host("192.168.4.22") // ip on network
        let port = NWEndpoint.Port(integerLiteral: 8080) // same port as server
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        connection?.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                isConnected = true
                startReceiving()
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
    
    func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data = data, let response = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    serverResponse += response
                }
            }
            if isComplete {
                disconnectFromServer()
            } else if let error = error {
                print("Error receiving data: \(error)")
            } else {
                startReceiving()
            }
        }
    }
    
    func sendCommand() {
        guard let connection = connection, isConnected, !commandInput.isEmpty else { return }
        
        let command = commandInput.data(using: .utf8)!
        connection.send(content: command, completion: .contentProcessed({ error in
            if let error = error {
                print("Failed to send message: \(error)")
            } else {
                DispatchQueue.main.async {
                    serverResponse += "\n$ \(commandInput)\n" // Add command to output
                    commandInput = ""
                }
            }
        }))
    }
    
    func disconnectFromServer() {
        connection?.cancel()
    }
}

struct LandingView: View {
    var connectAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Landing Screen")
                .font(.largeTitle)
                .padding()
            
            Button("Connect") {
                connectAction()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

struct TerminalView: View {
    @Binding var commandInput: String
    @Binding var serverResponse: String
    var sendCommand: () -> Void

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text(serverResponse)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                    
                    HStack {
                        Text("$") // Terminal prompt
                            .font(.system(.body, design: .monospaced))
                        TextField("Enter command", text: $commandInput, onCommit: {
                            sendCommand()
                        })
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(.body, design: .monospaced))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .background(Color.black)
            .foregroundColor(Color.white)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
