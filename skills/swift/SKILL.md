---
name: swift
description: Swift and SwiftUI patterns for iOS development. Triggers on: .swift files or Package.swift.
version: 1.0.0
detect: ["Package.swift", "*.xcodeproj"]
---

# Swift / SwiftUI

Native iOS development patterns.

## SwiftUI Basics

```swift
struct ContentView: View {
    @State private var count = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(count)")
                .font(.title)
            
            Button("Increment") {
                count += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

## Data Flow

```swift
// Observable (iOS 17+)
@Observable
class ViewModel {
    var items: [Item] = []
    var isLoading = false
    
    func loadItems() async {
        isLoading = true
        items = await api.fetchItems()
        isLoading = false
    }
}

// Usage
struct ItemList: View {
    @State private var viewModel = ViewModel()
    
    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task {
            await viewModel.loadItems()
        }
    }
}
```

## Navigation

```swift
struct App: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
                    .navigationDestination(for: Item.self) { item in
                        ItemDetailView(item: item)
                    }
            }
        }
    }
}
```

## Networking

```swift
actor APIClient {
    func fetch<T: Decodable>(_ endpoint: String) async throws -> T {
        let url = URL(string: "https://api.example.com\(endpoint)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

## Persistence

```swift
// SwiftData
@Model
class Task {
    var title: String
    var isCompleted: Bool
    
    init(title: String) {
        self.title = title
        self.isCompleted = false
    }
}

// Usage
@Query var tasks: [Task]
@Environment(\.modelContext) var context

func addTask(_ title: String) {
    context.insert(Task(title: title))
}
```
