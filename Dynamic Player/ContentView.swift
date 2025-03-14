//
//  ContentView.swift
//  Dynamic Player
//
//  Created by Leonardo Azevedo and Chalie Fator on 1/31/25.
//

import SwiftUI
import AVFoundation
import SpriteKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var showPlayerScreen = false // Controls navigation

    var body: some View {
        ZStack {
            if showPlayerScreen {
                PlayerView(showPlayerScreen: $showPlayerScreen)
                    .transition(.move(edge: .bottom)) // Smooth transition
            } else {
                SplashScreen(showPlayerScreen: $showPlayerScreen)
                    .transition(.move(edge: .top))
            }
        }
        .animation(.easeInOut, value: showPlayerScreen)
    }
}

// MARK: - Splash Screen
struct SplashScreen: View {
    @Binding var showPlayerScreen: Bool

    var body: some View {
        ZStack {
            Image("backgroundImage") // Uses background.png from Assets
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            Text("Welcome")
                .font(.system(size: 72, weight: .bold, design: .default))
                .foregroundColor(.white)
                .shadow(radius: 4, x: 2, y: 2)
                .padding()
            VStack {
                Spacer()
                Text("Swipe")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .shadow(radius: 4, x: 2, y: 2)
                    .padding(.bottom, 50)
            }
        }
        .gesture(
            DragGesture().onEnded { gesture in
                if gesture.translation.height < -100 { // Detect swipe up
                    withAnimation {
                        showPlayerScreen = true
                    }
                }
            }
        )
    }
}
//MARK: Library View
struct LibraryView: View {
    @Binding var songFiles: [(data: Data, filename: String)]
    var selectSong: (Int) -> Void
    @Binding var showLibrary: Bool

    var body: some View {
        VStack {
            Text("Library")
                .font(.largeTitle)
                .padding()
            
            List(songFiles.indices, id: \..self) { index in
                Button(action: { selectSong(index); showLibrary = false }) {
                    Text(songFiles[index].filename)
                }
            }
            
            Button("Close") {
                withAnimation { showLibrary = false }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Main Player Screen
struct PlayerView: View {
    @Binding var showPlayerScreen: Bool
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showLibrary = false
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
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height) * 0.95
                
                SpriteView(scene: MikuAnimationScene(), options: [.allowsTransparency])
                    .frame(width: size, height: size)
                    .cornerRadius(size * 0.1)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }

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
        .navigationTitle("Dynamic Player")
        .gesture(
            DragGesture().onEnded { gesture in
                if gesture.translation.height > 100 { // Detect swipe down
                    withAnimation {
                        showPlayerScreen = false
                    }
                }
            }
        )
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
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    let data = try Data(contentsOf: url)
                    return (data: data, filename: url.lastPathComponent)
                } else {
                    throw NSError(domain: NSCocoaErrorDomain, code: 257, userInfo: [NSLocalizedDescriptionKey: "Permission to access file denied"])
                }
            }
            songFiles.append(contentsOf: songData)
            
            if songFiles.count == 1 {
                loadSong(at: 0)
            }
        } catch {
            print("Error loading files: \(error)")
        }
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
