//
//  ContentView.swift
//  Dynamic Player
//
//  Created by Leonardo Azevedo on 1/31/25.
//

import SwiftUI
import AVFoundation
import SpriteKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var songTitle = "No Song Loaded"
    @State private var artistName = "Unknown Artist"
    @State private var progress: Double = 0.0
    @State private var duration: Double = 1.0
    @State private var currentTime: Double = 0.0
    
    @State private var songFiles: [(data: Data, filename: String)] = []
    @State private var currentSongIndex = 0
    @State private var timer: Timer?
    @State private var showingPicker = false
    var body: some View {
        VStack {
            SpriteView(scene: MikuAnimationScene(), options: [.allowsTransparency])
                .frame(width: 400, height: 400)
            
            Text("\(songTitle) - \(artistName)")
                .font(.headline)
                .padding()
            
            VStack {
                Slider(value: $progress, in: 0...duration, onEditingChanged: { _ in
                    audioPlayer?.currentTime = progress
                })
                
                HStack {
                    Text(timeString(time: currentTime))
                    Spacer()
                    Text(timeString(time: duration))
                }
                .font(.caption)
                .padding(.horizontal)
            }
            
            HStack {
                Button(action: prevSong) { Image(systemName: "backward.fill") }
                Button(action: togglePlayPause) { Image(systemName: isPlaying ? "pause.fill" : "play.fill") }
                Button(action: nextSong) { Image(systemName: "forward.fill") }
            }
            .font(.largeTitle)
            .padding()
            
            Button("Import Songs") {
                showingPicker.toggle()
            }
            .padding()
            .sheet(isPresented: $showingPicker) {
                DocumentPickerView { urls in
                    importSongs(from: urls)
                }
            }
        }
        .padding()
    }
    
    func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
            startTimer()
        }
        isPlaying.toggle()
    }
    
    func nextSong() {
        if songFiles.isEmpty { return }
        currentSongIndex = (currentSongIndex + 1) % songFiles.count
        loadSong(at: currentSongIndex)
    }
    
    func prevSong() {
        if songFiles.isEmpty { return }
        currentSongIndex = (currentSongIndex - 1 + songFiles.count) % songFiles.count
        loadSong(at: currentSongIndex)
    }
    
    func loadSong(at index: Int) {
        let song = songFiles[index]
        do {
            audioPlayer = try AVAudioPlayer(data: song.data)
            songTitle = song.filename
            artistName = "Unknown Artist"
            duration = audioPlayer?.duration ?? 1.0
            progress = 0.0
            isPlaying = false
            togglePlayPause()
        } catch {
            print("Error loading song: \(error)")
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard let player = audioPlayer else { return }
            currentTime = player.currentTime
            progress = player.currentTime
            
            if player.currentTime >= player.duration {
                nextSong()
            }
        }
    }
    
    func timeString(time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func importSongs(from urls: [URL]) {
        do {
            let songData = try urls.map { (url: URL) -> (data: Data, filename: String) in
                // Check if the URL is coming from iCloud or a protected location
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() } // Make sure to stop accessing after the operation
                    
                    // Read file data
                    let data = try Data(contentsOf: url)
                    return (data: data, filename: url.lastPathComponent)
                } else {
                    throw NSError(domain: NSCocoaErrorDomain, code: 257, userInfo: [NSLocalizedDescriptionKey: "Permission to access file denied"])
                }
            }
            songFiles.append(contentsOf: songData) // Append to the song list
            
            // If it's the first song, load it automatically
            if songFiles.count == 1 {
                loadSong(at: 0)
            }
        } catch {
            print("Error loading files: \(error)")
        }
    }
    
    // MARK: - Miku Animation Scene
    class MikuAnimationScene: SKScene {
        override func didMove(to view: SKView) {
            let miku = SKSpriteNode(imageNamed: "miku")
            miku.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(miku)
            
            let moveUp = SKAction.moveBy(x: 0, y: 80, duration: 1)
            let moveDown = SKAction.moveBy(x: 0, y: -80, duration: 1)
            let rotate = SKAction.rotate(byAngle: .pi / 8, duration: 0.5)
            let sequence = SKAction.sequence([moveUp, rotate, moveDown, rotate.reversed()])
            miku.run(SKAction.repeatForever(sequence))
        }
    }
    
    // MARK: - Document Picker View
    struct DocumentPickerView: UIViewControllerRepresentable {
        var onDocumentsPicked: ([URL]) -> Void
        
        func makeCoordinator() -> Coordinator {
            return Coordinator(onDocumentsPicked: onDocumentsPicked)
        }
        
        func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio])
            picker.allowsMultipleSelection = true
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
        
        class Coordinator: NSObject, UIDocumentPickerDelegate {
            var onDocumentsPicked: ([URL]) -> Void
            
            init(onDocumentsPicked: @escaping ([URL]) -> Void) {
                self.onDocumentsPicked = onDocumentsPicked
            }
            
            func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                onDocumentsPicked(urls)
            }
            
            func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
                // Handle cancellation if needed
            }
        }
    }
    
    // MARK: - App Entry Point
    @main
    struct MikuApp: App {
        var body: some Scene {
            WindowGroup {
                ContentView()
            }
        }
    }
}
