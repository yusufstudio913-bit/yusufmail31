import SwiftUI
import UniformTypeIdentifiers

// 🔗 BACKEND URL (Fly.io)
private let BACKEND_URL = "https://yusufmail31.fly.dev/send"

@main
struct YusufMail31App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {

    @State private var to = ""
    @State private var subject = ""
    @State private var message = ""
    @State private var selectedFile: URL?
    @State private var status = ""

    @State private var showFilePicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {

                    Text("YusufMail31")
                        .font(.title2)
                        .bold()

                    TextField("Alıcı e-posta", text: $to)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)

                    TextField("Konu", text: $subject)
                        .textFieldStyle(.roundedBorder)

                    TextEditor(text: $message)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.gray.opacity(0.3))
                        )

                    Button("📎 Dosya Seç") {
                        showFilePicker = true
                    }

                    if let file = selectedFile {
                        Text(file.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Button("📨 Gönder") {
                        send()
                    }
                    .buttonStyle(.borderedProminent)

                    Text(status)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .navigationTitle("Mail Gönder")
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .image, .plainText],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result {
                selectedFile = urls.first
            }
        }
    }

    // =========================
    // BACKEND'E POST
    // =========================
    private func send() {
        status = "⏳ Gönderiliyor..."

        guard let url = URL(string: BACKEND_URL) else {
            status = "❌ URL hatalı"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()

        func addField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        addField("to", to)
        addField("subject", subject)
        addField("message", message)

        if let fileURL = selectedFile,
           let fileData = try? Data(contentsOf: fileURL) {

            let filename = fileURL.lastPathComponent

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n"
                    .data(using: .utf8)!
            )
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                status = (code == 200 || code == 201)
                    ? "✅ Mail gönderildi"
                    : "❌ Gönderim hatası (\(code))"
            }
        }.resume()
    }
}