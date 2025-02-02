//
//  ContentView.swift
//  Dynamic Player
//
//  Created by Leonardo Azevedo on 1/31/25.
//

import SwiftUI
import Firebase

struct ContentView: View {
    init(){
        FirebaseApp.configure()
    }
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Text("Welcome to the")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    
                Text("Miku Miku Player!")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    
                    // Login Button
                NavigationLink(destination: LoginView()) {
                    Text("Login")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 150)
                        .background(Color.cyan)
                        .cornerRadius(10)
                    }
                    
                    // Guest Button
                NavigationLink(destination: LibraryView()) {
                    Text("Guest")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 150)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
    }
}
struct LibraryView: View {
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack {
                Text("Welcome to the Library")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
            }
            .padding()
        }
    }
}
#Preview {
    ContentView()
}
