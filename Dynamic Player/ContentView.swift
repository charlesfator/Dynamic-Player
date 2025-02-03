//
//  ContentView.swift
//  Dynamic Player
//
//  Created by Leonardo Azevedo on 1/31/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
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
                    
//                    struct LibraryView: View {
//                        var body: some View {
//                            ZStack {
//                                Color.white.edgesIgnoringSafeArea(.all)
//                                VStack {
//                                    Text("Welcome to the Library")
//                                        .font(.largeTitle)
//                                        .bold()
//                                    
//                                    Spacer()
//                                }
//                                .padding()
//                            }
//                        }
//                    }
                }
            }
        }
    }
}
