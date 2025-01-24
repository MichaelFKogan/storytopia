import SwiftUI
import StoreKit

extension Color {
    init(hex: String) {
        // Ensure that the hex string starts with '#' and remove it
        let hexSanitized = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        
        // If the string is 6 characters long, it's a valid RGB hex code
        if hexSanitized.count == 6 {
            let scanner = Scanner(string: hexSanitized)
            var hexValue: UInt64 = 0
            
            // Scan the hex string to get the color components
            if scanner.scanHexInt64(&hexValue) {
                let r = Double((hexValue & 0xFF0000) >> 16) / 255.0
                let g = Double((hexValue & 0x00FF00) >> 8) / 255.0
                let b = Double(hexValue & 0x0000FF) / 255.0
                self.init(red: r, green: g, blue: b)
            } else {
                self.init(.gray) // Default to gray if invalid hex
            }
        } else {
            self.init(.gray) // Default to gray if invalid hex length
        }
    }
}

// Modify Story to generate an ID if none is provided
struct Story: Codable, Identifiable {
    var id: UUID
    var url: String?
    let title: String
    let genre: String
    var synopsis: String?
    let story: String
    var hasLoadedURL: Bool = false // Default to not loaded

    enum CodingKeys: String, CodingKey {
        case url
        case title
        case genre
        case synopsis
        case story
    }

    // Use a custom initializer to assign a UUID
    init(title: String, genre: String, synopsis: String, url: String, story: String) {
        self.id = UUID() // Generate a new UUID for each story
        self.url = url
        self.title = title
        self.genre = genre
        self.synopsis = synopsis
        self.story = story
    }

    // Custom decoding to generate id if missing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // Generate a new UUID
        self.url = try container.decode(String.self, forKey: .url)
        self.title = try container.decode(String.self, forKey: .title)
        self.genre = try container.decode(String.self, forKey: .genre)
        self.synopsis = try container.decodeIfPresent(String.self, forKey: .synopsis)
        self.story = try container.decode(String.self, forKey: .story)
    }
}

// ViewModel to Fetch All Stories
class StoryViewModel: ObservableObject {
    @Published var stories: [Story] = []

    func fetchStories() {
        guard let url = URL(string: "https://stories-server.vercel.app/stories") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching stories: \(error)")
                return
            }

            if let data = data {
                do {
                    let decodedStories = try JSONDecoder().decode([Story].self, from: data)
                    DispatchQueue.main.async {
                        print(decodedStories) // Check if both stories are decoded correctly
                        self.stories = decodedStories
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }

    func fetchImageURL(for story: Story) {
        // Simulate fetching a URL lazily
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            if let index = self.stories.firstIndex(where: { $0.id == story.id }) {
                DispatchQueue.main.async {
                    self.stories[index].url = story.url // Update the URL
                    self.stories[index].hasLoadedURL = true // Mark as loaded
                }
            }
        }
    }
}


// Struct to match the response from the server
struct StoryFile: Codable {
    let date: String
    let stories: [Story]
}

struct DateStory: Decodable {
    let date: String
    var stories: [Story] // Assuming Story is already decodable
}

// ViewModel to Fetch Stories by date
class NewViewModel: ObservableObject {
    @Published var dateStories: [DateStory] = []

    func fetchStories() {
        guard let url = URL(string: "https://stories-server.vercel.app/date") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching stories: \(error)")
                return
            }

            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode([DateStory].self, from: data)
                    DispatchQueue.main.async {
                        self.dateStories = decodedResponse  // Set the date-stories array
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }

    func fetchImageURL(for story: Story) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            if let index = self.dateStories.flatMap({ $0.stories }).firstIndex(where: { $0.id == story.id }) {
                DispatchQueue.main.async {
                    self.dateStories[index / self.dateStories.count].stories[index % self.dateStories.count].url = story.url  // Update the URL
                    self.dateStories[index / self.dateStories.count].stories[index % self.dateStories.count].hasLoadedURL = true // Mark as loaded
                }
            }
        }
    }
}



extension Notification.Name {
    static let scrollToTop = Notification.Name("scrollToTop")
}












struct ContentView: View {
    
    @StateObject private var viewModel = StoryViewModel()
    @State private var selectedTab: Int = 0
    
        init() {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black
            appearance.shadowColor = UIColor.gray
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem {
                Image(systemName: "house")
                Text("Home")
            }
            .tag(0) // Tag to identify the tab
            
            NavigationStack {
                NewView(selectedTab: $selectedTab)
            }
            .tabItem {
                Image(systemName: "star")
                Text("New")
            }
            .tag(1)
            
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    Text("Coming\nSoon")
                        .font(.custom("Futura", size: 50))
                        .fontWeight(.heavy)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: "#de9590"))
                        .tracking(5)
                        .shadow(color: Color(hex: "#275faa").opacity(1), radius: 0, x: 5, y: 5)
                        .padding(.horizontal, 20)
                        .background(Color.black.edgesIgnoringSafeArea(.all))
                }
                .tabItem {
                    Image(systemName: "rectangle.grid.2x2")
                    Text("Genre")
                }
            
            RandomView(selectedTab: $selectedTab) // Pass the binding to RandomView
                .environmentObject(viewModel)
                .tabItem {
                    Label("Random", systemImage: "shuffle")
                }
                .tag(3) // Use tag 3 for the Random tab
        }
        .onAppear {
            viewModel.fetchStories() // Fetch stories once when the app starts
        }
    }
}












struct HomeView: View {
    @StateObject private var viewModel = StoryViewModel()
    @Binding var selectedTab: Int  // Binding to selected tab
    @State private var selectedStory: Story? = nil
    @State private var selectedStoryIndex: Int? = nil
    @State private var showNewView: Bool = false
    @State private var scrollToTopID = "top"  // Identifier for the top

    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color.black
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    ScrollViewReader { proxy in
                    ScrollView {
                        VStack {
                            
                            
                            VStack{
                                // Optional Title and Subtitle
                                Text("STORYTOPIA")
                                    .font(.custom("Futura", size: 44))
                                    .fontWeight(.heavy)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color(hex: "#de9590"))
                                    .tracking(5) // Letter spacing
                                    .shadow(color: Color(hex: "#275faa").opacity(1), radius: 0, x: 5, y: 5) // Shadow
                                    .padding(.horizontal, 20)
//                                    .id(scrollToTopID)
                                
                                VStack {
                                    Text("AI Generated Short Stories")
                                        .font(.custom("Futura", size: 18))
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.top, 0)
                                        .multilineTextAlignment(.center)
                                    
                                    
                                    //                                Text("Total Count: \(viewModel.stories.count) Stories") // Dynamic count
                                    //                                    .font(.custom("Futura", size: 14))
                                    //                                    .fontWeight(.light)
                                    //                                    .foregroundColor(.gray)
                                }
                            }.padding(.bottom, 30)
                            
                            // Lazy Grid for Images
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 3) {
                                ForEach(viewModel.stories.indices, id: \.self) { index in
                                    let item = viewModel.stories[index]
                                    NavigationLink(destination: StoryView(
                                        imageUrl: item.url ?? "",
                                        title: item.title,
                                        genre: item.genre,
                                        synopsis: item.synopsis ?? "",
                                        story: item.story,
                                        currentIndex: index,
                                        selectedStoryIndex: $selectedStoryIndex,
                                        viewModel: viewModel  // Pass viewModel to StoryView
                                    ),
                                                   tag: index, // Associate each item with an index
                                                   selection: $selectedStoryIndex ) {
                                        ZStack {
                                            // AsyncImage for image loading
                                            AsyncImage(url: URL(string: item.url ?? "")) { phase in
                                                switch phase {
                                                case .empty:
                                                    Color.gray
                                                        .frame(width: UIScreen.main.bounds.width / 3, height: 200)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: UIScreen.main.bounds.width / 3, height: 200)
                                                        .clipped()
                                                case .failure:
                                                    Color.gray
                                                        .frame(width: UIScreen.main.bounds.width / 3, height: 200)
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            
                                            // Title Overlay at the Bottom
                                            VStack {
                                                Spacer()
                                                Text(item.title)
                                                    .font(.custom("AvenirNext-Bold", size: 14))
                                                    .lineLimit(8)
                                                    .foregroundColor(.white)
                                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
                                                    .padding([.bottom, .leading], 10)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .multilineTextAlignment(.leading)
                                            }
                                        }
                                    }
                                   .onAppear {
                                       if !item.hasLoadedURL {
                                           viewModel.fetchImageURL(for: item)
                                       }
                                   }
                                }
                            }
                            .padding(.top, 0)
                        }.padding(.bottom, 100)
//                            .onChange(of: selectedTab) { newTab in
//                                if newTab == 0 {
//                                    // Scroll to the top of the HomeView when selected
//                                    withAnimation {
//                                        proxy.scrollTo(scrollToTopID, anchor: .top)
//                                    }
//                                }
//                            }
                    }
                }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchStories()
            }
            
        }
    }
}












struct NewView: View {
    @StateObject private var viewModel = NewViewModel()
    @Binding var selectedTab: Int
    @State private var selectedStory: Story? = nil
    @State private var selectedStoryIndex: Int? = nil
    @State private var showNewView: Bool = false
    @State private var scrollToTopID = "top"

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack {
                                // Loop through the date-stories array
                                ForEach(viewModel.dateStories, id: \.date) { dateStory in
                                    VStack {
                                        Text(dateStory.date)
                                            .font(.custom("Futura", size: 24))
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.top, 50)
//                                            .id(scrollToTopID)

                                        // LazyVGrid for Images
                                        LazyVGrid(columns: [
                                            GridItem(.flexible()),
                                            GridItem(.flexible()),
                                            GridItem(.flexible())
                                        ], spacing: 3) {
                                            ForEach(dateStory.stories.indices, id: \.self) { index in
                                                let item = dateStory.stories[index]
                                                NavigationLink(destination: StoryViewDate(
                                                    imageUrl: item.url ?? "",
                                                    title: item.title,
                                                    genre: item.genre,
                                                    synopsis: item.synopsis ?? "",
                                                    story: item.story,
                                                    currentIndex: index,
                                                    selectedStoryIndex: $selectedStoryIndex,
                                                    viewModel: viewModel)) {
                                                    ZStack {
                                                        AsyncImage(url: URL(string: item.url ?? "")) { phase in
                                                            switch phase {
                                                            case .empty:
                                                                Color.gray.frame(width: UIScreen.main.bounds.width / 3, height: 200)
                                                            case .success(let image):
                                                                image.resizable().scaledToFill().frame(width: UIScreen.main.bounds.width / 3, height: 200).clipped()
                                                            case .failure:
                                                                Color.gray.frame(width: UIScreen.main.bounds.width / 3, height: 200)
                                                            @unknown default:
                                                                EmptyView()
                                                            }
                                                        }
                                                        VStack {
                                                            Spacer()
                                                            Text(item.title)
                                                                .font(.custom("AvenirNext-Bold", size: 14))
                                                                .lineLimit(8)
                                                                .foregroundColor(.white)
                                                                .shadow(color: .black, radius: 2, x: 1, y: 1)
                                                                .padding([.bottom, .leading], 10)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                                .multilineTextAlignment(.leading)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.top, 0)
                                    }
                                }
                            }
                            .padding(.bottom, 100)
//                            .onChange(of: selectedTab) { newTab in
//                               if newTab == 1 { // When the 'New' tab is selected
//                                   withAnimation {
//                                       proxy.scrollTo(scrollToTopID, anchor: .top)
//                                   }
//                               }
//                           }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchStories()
            }
        }
    }
}

















struct StoryView: View {
    var imageUrl: String
    var title: String
    var genre: String
    var synopsis: String
    var story: String

    var currentIndex: Int
    @Binding var selectedStoryIndex: Int?
    var viewModel: StoryViewModel  // Receive viewModel
    
    @Environment(\.presentationMode) var presentationMode
    @State private var dragAmount: CGFloat = 0

    // State for manual navigation
    @State private var navigateToNext = false
    @State private var showPopup = false // State for showing the popup
    @State private var scrollOffset: CGFloat = 0
    
    // Split the story into paragraphs
     private var paragraphs: [String] {
         return story.components(separatedBy: "\n").filter { !$0.isEmpty }
     }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                Color.gray.frame(height: 300)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                            case .failure:
                                Color.gray.frame(height: 300)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        Text(title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        Text(genre)
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                        
                        Text(synopsis)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .italic()
                        
//                        Text(story)
//                            .font(.system(size: 22))
//                            .fontWeight(.medium)
//                            .foregroundColor(.white)
//                            .padding(.horizontal, 20)
//                            .padding(.top, 0)
//                            .lineSpacing(0)
                        
                        // Display first 5 paragraphs without blur
                        ForEach(0..<min(paragraphs.count, 5), id: \.self) { index in
                            Text(paragraphs[index])
                                .font(.system(size: 22))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                                .lineSpacing(0)
                        }
                        
                        // Subscription Text and Button
                        VStack {
                            Text("Subscribe for Full Access")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            Text("Get unlimited access to all stories. \n$9.99/month. Cancel anytime.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding()
                            
                            Button(action: {
                                // Add subscription logic here
                            }) {
                                Text("Subscribe Now")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .padding(.top, 10)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Display paragraphs after the 5th with blur
                        ForEach(5..<paragraphs.count, id: \.self) { index in
                            Text(paragraphs[index])
                                .font(.system(size: 22))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                                .lineSpacing(0)
                                .blur(radius: 5) // Apply blur effect
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(
                        destination: NextView(
                            imageUrl: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].url ?? "",
                            title: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].title,
                            genre: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].genre,
                            synopsis: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].synopsis ?? "",
                            story: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].story,
                            currentIndex: (currentIndex + 1) % viewModel.stories.count,
                            selectedStoryIndex: $selectedStoryIndex,
                            viewModel: viewModel
                        ),
                        isActive: $navigateToNext
                    ) {
                        HStack(spacing: 4) {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.blue) // Matches the navigation bar style
                    }
                }
            }
            .padding([.top, .trailing], 16)
            
        }
        .navigationTitle("")
        .navigationBarHidden(false)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragAmount = value.translation.width
                }
                .onEnded { value in
                    // Swipe left (forward): Navigate to next story
                    if dragAmount < -50 {
                        navigateToNext = true
                    }
                    // Swipe right (backward): Go back (dismiss the view)
                    else if dragAmount > 50 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
    }
}











struct NextView: View {
    var imageUrl: String
    var title: String
    var genre: String
    var synopsis: String
    var story: String
    
    var currentIndex: Int
    @Binding var selectedStoryIndex: Int?
    var viewModel: StoryViewModel  // Receive viewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var dragAmount: CGFloat = 0
    @State private var navigateToNext = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                Color.gray.frame(height: 300)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                            case .failure:
                                Color.gray.frame(height: 300)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        Text(title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        Text(genre)
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                        
                        Text(synopsis)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .italic()
                        
                        Text(story)
                            .font(.system(size: 22))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 0)
                            .lineSpacing(0)
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(
                        destination: NextView(
                            imageUrl: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].url ?? "",
                            title: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].title,
                            genre: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].genre,
                            synopsis: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].synopsis ?? "",
                            story: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].story,
                            currentIndex: (currentIndex + 1) % viewModel.stories.count,
                            selectedStoryIndex: $selectedStoryIndex,
                            viewModel: viewModel
                        ),
                        isActive: $navigateToNext
                    ) {
                        Label("Next", systemImage: "chevron.right")
                            .labelStyle(TitleAndIconLabelStyle())
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                    }
                }
            }
            .padding([.top, .trailing], 16)
        }
        .navigationTitle("")
        .navigationBarHidden(false)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragAmount = value.translation.width
                }
                .onEnded { value in
                    // Swipe left (forward): Navigate to next story
                    if dragAmount < -50 {
                        navigateToNext = true
                    }
                    // Swipe right (backward): Go back (dismiss the view)
                    else if dragAmount > 50 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
    }
}














struct StoryViewDate: View {
    var imageUrl: String
    var title: String
    var genre: String
    var synopsis: String
    var story: String

    var currentIndex: Int
    @Binding var selectedStoryIndex: Int?
    var viewModel: NewViewModel  // Receive viewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var dragAmount: CGFloat = 0
    @State private var navigateToNext = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                Color.gray.frame(height: 300)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                            case .failure:
                                Color.gray.frame(height: 300)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        Text(title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        Text(genre)
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                        
                        Text(synopsis)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .italic()
                        
                        Text(story)
                            .font(.system(size: 22))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 0)
                            .lineSpacing(0)
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    NavigationLink(
//                        destination: NextViewDate(
//                            imageUrl: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].url ?? "",
//                            title: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].title,
//                            genre: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].genre,
//                            synopsis: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].synopsis ?? "",
//                            story: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].story,
//                            currentIndex: (currentIndex + 1) % viewModel.stories.count,
//                            selectedStoryIndex: $selectedStoryIndex,
//                            viewModel: viewModel
//                        ),
//                        isActive: $navigateToNext
//                    ) {
//                        HStack(spacing: 4) {
//                            Text("Next")
//                            Image(systemName: "chevron.right")
//                        }
//                        .foregroundColor(.blue)
//                    }
//                }
//            }
            .padding([.top, .trailing], 16)
        }
        .navigationTitle("")
        .navigationBarHidden(false)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragAmount = value.translation.width
                }
                .onEnded { value in
                    // Swipe left (forward): Navigate to next story
                    if dragAmount < -50 {
                        navigateToNext = true
                    }
                    // Swipe right (backward): Go back (dismiss the view)
                    else if dragAmount > 50 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
    }
}















//struct NextViewDate: View {
//    var imageUrl: String
//    var title: String
//    var genre: String
//    var synopsis: String
//    var story: String
//    
//    var currentIndex: Int
//    @Binding var selectedStoryIndex: Int?
//    var viewModel: NewViewModel  // Receive viewModel
//    
//    @Environment(\.presentationMode) var presentationMode
//    
//    @State private var dragAmount: CGFloat = 0
//    @State private var navigateToNext = false
//
//    var body: some View {
//        ZStack {
//            Color.black.edgesIgnoringSafeArea(.all)
//
//            VStack{
//                ScrollView {
//                    VStack(alignment: .leading) {
//                        AsyncImage(url: URL(string: imageUrl)) { phase in
//                            switch phase {
//                            case .empty:
//                                Color.gray.frame(height: 300)
//                            case .success(let image):
//                                image
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(maxWidth: .infinity)
//                                    .clipped()
//                            case .failure:
//                                Color.gray.frame(height: 300)
//                            @unknown default:
//                                EmptyView()
//                            }
//                        }
//                        
//                        Text(title)
//                            .font(.largeTitle)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                            .padding(.horizontal, 20)
//                        
//                        Text(genre)
//                            .font(.title2)
//                            .foregroundColor(.white.opacity(0.8))
//                            .padding(.horizontal, 20)
//                        
//                        Text(synopsis)
//                            .font(.body)
//                            .foregroundColor(.white.opacity(0.8))
//                            .padding(.horizontal, 20)
//                            .padding(.top, 4)
//                            .italic()
//                        
//                        Text(story)
//                            .font(.system(size: 22))
//                            .fontWeight(.medium)
//                            .foregroundColor(.white)
//                            .padding(.horizontal, 20)
//                            .padding(.top, 0)
//                            .lineSpacing(0)
//
//                        Spacer()
//                    }
//                    .padding(.top)
//                }
//            }
//            
//            .navigationTitle("")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    NavigationLink(
//                        destination: NextViewDate(
//                            imageUrl: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].url ?? "",
//                            title: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].title,
//                            genre: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].genre,
//                            synopsis: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].synopsis ?? "",
//                            story: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].story,
//                            currentIndex: (currentIndex + 1) % viewModel.stories.count,
//                            selectedStoryIndex: $selectedStoryIndex,
//                            viewModel: viewModel
//                        ),
//                        isActive: $navigateToNext
//                    ) {
//                        Label("Next", systemImage: "chevron.right")
//                            .labelStyle(TitleAndIconLabelStyle())
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(Color.blue)
//                            .cornerRadius(8)
//                            .shadow(radius: 5)
//                    }
//                }
//            }
//            .padding([.top, .trailing], 16)
//        }
//        .navigationTitle("")
//        .navigationBarHidden(false)
//        .gesture(
//            DragGesture()
//                .onChanged { value in
//                    dragAmount = value.translation.width
//                }
//                .onEnded { value in
//                    // Swipe left (forward): Navigate to next story
//                    if dragAmount < -50 {
//                        navigateToNext = true
//                    }
//                    // Swipe right (backward): Go back (dismiss the view)
//                    else if dragAmount > 50 {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                }
//        )
//    }
//}







struct RandomView: View {
    @EnvironmentObject var viewModel: StoryViewModel
    @State private var randomStory: Story?
    @Binding var selectedTab: Int
    
    @State private var dragAmount: CGFloat = 0
    @State private var navigateToNext = false

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            if let story = randomStory {
                VStack {
                    // Display the story content
                    ScrollView {
                        VStack(alignment: .leading) {
                            AsyncImage(url: URL(string: story.url ?? "")) { phase in
                                switch phase {
                                case .empty: Color.gray.frame(height: 300)
                                case .success(let image): image.resizable().scaledToFit().frame(maxWidth: .infinity)
                                case .failure: Color.gray.frame(height: 300)
                                @unknown default: EmptyView()
                                }
                            }

                            Text(story.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            Text(story.genre)
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                            
                            Text(story.synopsis ?? "")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.top, 4)
                                .italic()
                            
                            Text(story.story)
                                .font(.system(size: 22))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 0)
                                .lineSpacing(0)
                        }
                        .padding()
                    }

                    Spacer() // Push everything up to leave space at the bottom
                }
            } else if viewModel.stories.isEmpty {
                ProgressView().progressViewStyle(CircularProgressViewStyle())
            } else {
                ProgressView()
                    .onAppear {
                        loadRandomStory() // Load a random story when the view appears
                    }
            }

            // "Next" Button positioned at the bottom right, above the TabView shuffle button
            VStack {
                Spacer() // Push the button to the bottom

                HStack {
                    Spacer() // Push the button to the right
                    Button(action: {
                        loadRandomStory() // Load a new random story when pressed
                    }) {
                        Text("Next")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    }
                    .padding(.bottom, 20) // Add some bottom padding for the button
                    .padding(.trailing, 20) // Add some trailing padding to place it on the right
                }
            }
        }
        .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragAmount = value.translation.width
                        }
                        .onEnded { value in
                            // Trigger action only for a left swipe (negative dragAmount)
                            if dragAmount < -50 {
                                loadRandomStory()
                            }
                        }
                )
    }

    // Function to load a random story
    private func loadRandomStory() {
        randomStory = viewModel.stories.randomElement()
    }
}





























struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
