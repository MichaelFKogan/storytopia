import SwiftUI




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






class GenreViewModel: ObservableObject {
    @Published var genres: [String: [String]] = [:] // Dictionary to store grouped genres
    
    func fetchGenres(from stories: [Story]) {
        var genreDictionary: [String: [String]] = [:]
        
        // Extract all unique genres
        let allGenres = stories.map { $0.genre } // Map to array of genre strings
        let uniqueGenres = Array(Set(allGenres)) // Remove duplicates
        
        // Group genres by their root word(s)
        for genre in uniqueGenres {
            let categories = extractCategories(from: genre) // Get all categories for this genre
            for category in categories {
                if genreDictionary[category] == nil {
                    genreDictionary[category] = []
                }
                genreDictionary[category]?.append(genre)
            }
        }
        
        // Sort categories alphabetically
        self.genres = genreDictionary
    }
    
    // Helper function to extract all components from the genre string
    func extractCategories(from genre: String) -> [String] {
        // Split the genre string by "/" and trim whitespace
        let components = genre.components(separatedBy: "/")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } // Remove any empty strings
        
        return components
    }
}





//class GenreViewModel: ObservableObject {
//    @Published var genres: [String: [String]] = [:] // Dictionary to store grouped genres
//    
//    // List of genres to hide
//    private let hiddenGenres: Set<String> = ["Gothic", "Noir", "Heartwarming", "Fiction", "Contemporary", "Historical", "Steampunk", "Western", "Urban Fantasy", "Young Adult"]
//    
//    func fetchGenres(from stories: [Story]) {
//        var genreDictionary: [String: [String]] = [:]
//        
//        // Extract all unique genres
//        let allGenres = stories.map { $0.genre } // Map to array of genre strings
//        let uniqueGenres = Array(Set(allGenres)) // Remove duplicates
//        
//        // Filter out hidden genres
//        let filteredGenres = uniqueGenres.filter { genre in
//            !hiddenGenres.contains(genre) && !hiddenGenres.contains(extractCategory(from: genre))
//        }
//        
//        // Group genres by their root word(s)
//        for genre in filteredGenres {
//            let category = extractCategory(from: genre)
//            if genreDictionary[category] == nil {
//                genreDictionary[category] = []
//            }
//            genreDictionary[category]?.append(genre)
//        }
//        
//        // Sort categories alphabetically
//        self.genres = genreDictionary
//    }
//    
//    // Helper function to extract the root word(s) from the genre string
//    private func extractCategory(from genre: String) -> String {
//        // Check if the genre contains "Slice Of Life"
//        if genre.contains("Slice of Life") {
//            return "Slice of Life"
//        } else if genre.contains("Urban Fantasy") {
//            return "Urban Fantasy"
//        } else if genre.contains("Young Adult") {
//            return "Young Adult"
//        }
//        
//        // Split the genre string by spaces or "/"
//        let components = genre.components(separatedBy: .whitespacesAndNewlines)
//            .flatMap { $0.components(separatedBy: "/") }
//            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
//        
//        // Extract the root word(s) (e.g., "Sci-Fi", "Horror", "Post-Apocalyptic")
//        if components.count > 1 {
//            // If the genre contains multiple parts, take the first part as the root
//            return components[0]
//        } else {
//            // If the genre is a single word, use it as the root
//            return components[0]
//        }
//    }
//}




extension Notification.Name {
    static let scrollToTop = Notification.Name("scrollToTop")
}












struct ContentView: View {
    @EnvironmentObject var storeManager: StoreManager  // Shared instance
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
            
            NavigationStack {
                        GenreView()
                            .environmentObject(viewModel)
                    }
                    .tabItem {
                        Image(systemName: "rectangle.grid.2x2")
                        Text("Genre")
                    }
                    .tag(2)
            
            RandomView(selectedTab: $selectedTab) // Pass the binding to RandomView
                .environmentObject(viewModel)
                .tabItem {
                    Label("Random", systemImage: "shuffle")
                }
                .tag(3) // Use tag 3 for the Random tab
        }
        .environmentObject(viewModel)
        .onAppear {
            // Fetch subscription status and check expiry when the app launches
               storeManager.fetchSubscriptionStatus()
               storeManager.checkSubscriptionExpiry()
               storeManager.initializeSubscription() // Initialize subscription logic
               print("App launched. isSubscribed: \(storeManager.isSubscribed)")
               viewModel.fetchStories() // Fetch stories once when the app starts
               storeManager.fetchProducts(productIDs: ["storytopia_monthly_subscription"])
        }
        .onReceive(storeManager.$purchasedProductIDs) { purchasedProductIDs in
            let newSubscriptionStatus = purchasedProductIDs.contains("storytopia_monthly_subscription")
            if storeManager.isSubscribed != newSubscriptionStatus {
                storeManager.isSubscribed = newSubscriptionStatus
                print("isSubscribed: \(storeManager.isSubscribed)") // Print only when the status changes
            }
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
    @State private var showModal = false
    // State for subscription
    @EnvironmentObject var storeManager: StoreManager  // Shared instance
    @State private var isRestoring = false
    
    var body: some View {
        ZStack {

                ZStack {
                    // Background color
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        if !storeManager.isSubscribed {
                            HStack {
                                Spacer()
                                Button(action: {
                                    showModal.toggle()  // Show the modal when button is tapped
                                }) {
                                    if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }),
                                       let introductoryPrice = product.introductoryPrice {
                                        Text("7-Day Free Trial")
                                            .font(.custom("Futura", size: 15))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .padding(.top, 20)
                                            .padding(.trailing, 20)
                                            .padding(.bottom, 10)
                                    }else{
                                        Text("Subscribe Now")
                                            .font(.custom("Futura", size: 15))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .padding(.top, 20)
                                            .padding(.trailing, 20)
                                            .padding(.bottom, 10)
                                    }
                                }
                            }
                        }
                        
                        
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
                                            .padding(.top, 10)
                                            .minimumScaleFactor(0.5) // Allows the text to scale down to 50% of its original size
                                            .lineLimit(1) // Ensures the text stays on a single line
                                        //                                    .id(scrollToTopID)
                                        
                                        VStack {
                                            Text("AI-Generated Short Stories")
                                                .font(.custom("Futura", size: 16))
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
                                                GeometryReader { geometry in
                                                    ZStack {
                                                        // AsyncImage for image loading
                                                        AsyncImage(url: URL(string: item.url ?? "")) { phase in
                                                            switch phase {
                                                            case .empty:
                                                                Color.gray
                                                                    .frame(width: geometry.size.width + 5, height: 200)
                                                            case .success(let image):
                                                                image
                                                                    .resizable()
                                                                    .scaledToFill()
                                                                    .frame(width: geometry.size.width + 5, height: 200)
                                                                    .clipped()
                                                            case .failure:
                                                                Color.gray
                                                                    .frame(width: geometry.size.width + 5, height: 200)
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
                                                .frame(height: 200) // Set a fixed height for the container
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
                                Spacer()
                                HStack {
                                    Spacer()
                                    // Terms of Use Link
                                    Button(action: {
                                        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text("Terms Of Use")
                                            .font(.custom("Futura", size: 12))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .padding(.top, 0)
                                            .padding(.bottom, 0)
                                    }
                                    
                                    Spacer()

                                    // Privacy Policy Link
                                    Button(action: {
                                        if let url = URL(string: "https://docs.google.com/document/d/1TwETsLxEmmsuHofUD4DVHT3SbShfENEfrU70CoQxTP8/edit?usp=sharing") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text("Privacy Policy")
                                            .font(.custom("Futura", size: 12))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .padding(.top, 0)
                                            .padding(.bottom, 0)
                                    }
                                    
                                    Spacer()

                                    // Restore Purchases Button
                                    Button(action: {
                                        isRestoring = true
                                        storeManager.restorePurchases()
                                    }) {
                                        if isRestoring {
                                            ProgressView()  // Spinner to indicate activity
                                                .progressViewStyle(CircularProgressViewStyle())
                                        } else {
                                            Text("Restore Purchases")
                                                .font(.custom("Futura", size: 12))
                                                .fontWeight(.regular)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .disabled(isRestoring)  // Disable the button during the restore process
                                    Spacer()
                                }.padding(.bottom, 20)
                            }
                        }
                    }
                }
                .navigationBarHidden(true)
                .onAppear {
                    viewModel.fetchStories()
                }
            
            // Show the SubscriptionModal if showModal is true
            if showModal {
                SubscriptionModal(showModal: $showModal)
                    .transition(.move(edge: .bottom))
                    .zIndex(1) // Ensure the modal appears above the main content
            }
        }
    }
}






struct SubscriptionModal: View {
    @Binding var showModal: Bool
    @EnvironmentObject var storeManager: StoreManager
    
    var body: some View {
        VStack {
            VStack {
                
                // Check if the user is eligible for the free trial
                 if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }),
                    let introductoryPrice = product.introductoryPrice {
                     
                     Text("7-Day Free Trial")
                         .font(.largeTitle)
                         .fontWeight(.bold)
                         .foregroundColor(.white)
                         .padding(.horizontal, 20)
                         .padding(.top, 20)
                     
                     Text("Then \(introductoryPrice.priceLocale.currencySymbol ?? "$")\(product.price)/month")
                         .font(.title2)
                         .fontWeight(.semibold)
                         .foregroundColor(.white)
                         .padding(.horizontal, 20)
                         .padding(.top, 5)
                     
                     // Additional description for the free trial
                     Text("You'll get full access to all stories for 7 days. After the trial, your subscription will automatically renew for \(introductoryPrice.priceLocale.currencySymbol ?? "$")\(product.price)/month unless canceled.")
                         .font(.subheadline)
                         .foregroundColor(.white.opacity(0.8))
                         .multilineTextAlignment(.center)
                         .padding(.horizontal, 20)
                         .padding(.top, 10)
                     
                     Text("To avoid charges, cancel anytime before the trial ends in your Apple ID settings.")
                         .font(.footnote)
                         .foregroundColor(.white.opacity(0.8))
                         .multilineTextAlignment(.center)
                         .padding(.horizontal, 20)
                         .padding(.top, 5)
                     
                     Button(action: {
                         if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }) {
                             storeManager.purchase(product: product)
                         }
                     }) {
                         Text("Start Free Trial")
                             .font(.headline)
                             .foregroundColor(.white)
                             .padding()
                             .background(Color.blue)
                             .cornerRadius(10)
                             .padding(.top, 10)
                     }
                     
                 } else {
                     Text("Subscribe for Full Access")
                         .font(.largeTitle)
                         .fontWeight(.bold)
                         .foregroundColor(.white)
                         .padding(.horizontal, 20)
                         .padding(.top, 20)
                         .multilineTextAlignment(.center)
                     
                     Text("$9.99/month")
                         .font(.title2)
                         .fontWeight(.semibold)
                         .foregroundColor(.white)
                         .padding(.horizontal, 20)
                         .padding(.top, 5)
                     
                     Button(action: {
                         if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }) {
                             storeManager.purchase(product: product)
                         }
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
                
                Text("Get unlimited access to all stories.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.bottom, 0)
                
                Text("Cancel anytime.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.top, 0)
                
                // Cancel text link
                Button(action: {
                    withAnimation {
                        showModal = false  // Close the modal
                    }
                }) {
                    Text("Cancel")
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .padding(.top, 5)
                }
                
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
            .padding(.horizontal, 20)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.black.opacity(0.6).edgesIgnoringSafeArea(.all))
        .onTapGesture {
            withAnimation {
                showModal = false  // Close the modal if tapped outside
            }
        }
        .onReceive(storeManager.$purchasedProductIDs) { purchasedProductIDs in
            if purchasedProductIDs.contains("storytopia_monthly_subscription") {
                showModal = false // Close modal after subscription
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
    @State private var showModal = false
    // State for subscription
    @EnvironmentObject var storeManager: StoreManager  // Shared instance
    @State private var isRestoring = false
    
    var body: some View {
        ZStack{

                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        if !storeManager.isSubscribed {
                            HStack {
                                Spacer()
                                Button(action: {
                                    showModal.toggle()  // Show the modal when button is tapped
                                }) {
                                    if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }),
                                       let introductoryPrice = product.introductoryPrice {
                                        Text("7-Day Free Trial")
                                            .font(.custom("Futura", size: 15))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .padding(.top, 20)
                                            .padding(.trailing, 20)
                                            .padding(.bottom, 10)
                                    }else{
                                        Text("Subscribe Now")
                                            .font(.custom("Futura", size: 15))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .padding(.top, 20)
                                            .padding(.trailing, 20)
                                            .padding(.bottom, 10)
                                    }
                                }
                            }
                        }
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack {
                                    // Loop through the date-stories array
                                    ForEach(viewModel.dateStories.indices, id: \.self) { batchIndex in
                                        let dateStory = viewModel.dateStories[batchIndex]
                                        VStack {
                                            Text(dateStory.date)
                                                .font(.custom("Futura", size: 24))
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.top, 10)
                                            //                                            .id(scrollToTopID)
                                            
                                            // LazyVGrid for Images
                                            LazyVGrid(columns: [
                                                GridItem(.flexible()),
                                                GridItem(.flexible()),
                                                GridItem(.flexible())
                                            ], spacing: 3) {
                                                ForEach(dateStory.stories.indices, id: \.self) { storyIndex in
                                                    let item = dateStory.stories[storyIndex]
                                                    NavigationLink(destination: StoryViewDate(
                                                        imageUrl: item.url ?? "",
                                                        title: item.title,
                                                        genre: item.genre,
                                                        synopsis: item.synopsis ?? "",
                                                        story: item.story,
                                                        batchIndex: batchIndex,
                                                        storyIndex: storyIndex,
                                                        selectedStoryIndex: $selectedStoryIndex,
                                                        viewModel: viewModel)) {
                                                            GeometryReader { geometry in
                                                                ZStack {
                                                                    // AsyncImage for image loading
                                                                    AsyncImage(url: URL(string: item.url ?? "")) { phase in
                                                                        switch phase {
                                                                        case .empty:
                                                                            Color.gray
                                                                                .frame(width: geometry.size.width + 5, height: 200)
                                                                        case .success(let image):
                                                                            image
                                                                                .resizable()
                                                                                .scaledToFill()
                                                                                .frame(width: geometry.size.width + 5, height: 200)
                                                                                .clipped()
                                                                        case .failure:
                                                                            Color.gray
                                                                                .frame(width: geometry.size.width + 5, height: 200)
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
                                                            .frame(height: 200) // Set a fixed height for the container
                                                        }
                                                }
                                            }
                                            .padding(.top, 0)
                                        }
                                    }
                                }
                                .padding(.bottom, 100)
                                HStack {
                                    Spacer()
                                    // Terms of Use Link
                                    Button(action: {
                                        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text("Terms Of Use")
                                            .font(.custom("Futura", size: 12))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .padding(.top, 0)
                                            .padding(.bottom, 0)
                                    }
                                    
                                    Spacer()

                                    // Privacy Policy Link
                                    Button(action: {
                                        if let url = URL(string: "https://docs.google.com/document/d/1TwETsLxEmmsuHofUD4DVHT3SbShfENEfrU70CoQxTP8/edit?usp=sharing") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text("Privacy Policy")
                                            .font(.custom("Futura", size: 12))
                                            .fontWeight(.regular)
                                            .foregroundColor(.white)
                                            .padding(.top, 0)
                                            .padding(.bottom, 0)
                                    }
                                    
                                    Spacer()

                                    // Restore Purchases Button
                                    Button(action: {
                                        isRestoring = true
                                        storeManager.restorePurchases()
                                    }) {
                                        if isRestoring {
                                            ProgressView()  // Spinner to indicate activity
                                                .progressViewStyle(CircularProgressViewStyle())
                                        } else {
                                            Text("Restore Purchases")
                                                .font(.custom("Futura", size: 12))
                                                .fontWeight(.regular)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .disabled(isRestoring)  // Disable the button during the restore process
                                    Spacer()
                                }.padding(.bottom, 20)
                            }
                        }
                    }
                }
                .navigationBarHidden(true)
                .onAppear {
                    viewModel.fetchStories()
                }
            
            // Show the SubscriptionModal if showModal is true
            if showModal {
                SubscriptionModal(showModal: $showModal)
                    .transition(.move(edge: .bottom))
                    .zIndex(1) // Ensure the modal appears above the main content
            }
        }
    }
}






struct GenreView: View {
    @EnvironmentObject var storyViewModel: StoryViewModel
    @StateObject private var genreViewModel = GenreViewModel()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    // Iterate over the grouped genres
                    ForEach(genreViewModel.genres.keys.sorted(), id: \.self) { category in
                        NavigationLink(destination: GenreDetailView(category: category, genreViewModel: genreViewModel)) {
                            Text(category)
                                .font(.custom("Futura", size: 24))
                                .fontWeight(.heavy)
                                .foregroundColor(Color(hex: "#de9590"))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.black)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: "#275faa"), lineWidth: 2)
                                )
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            genreViewModel.fetchGenres(from: storyViewModel.stories)
        }
    }
}







struct GenreDetailView: View {
    var category: String
    var genreViewModel: GenreViewModel // Add this line
    @EnvironmentObject var viewModel: StoryViewModel
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 3) {
                    // Filter stories by the selected category
                    ForEach(viewModel.stories.filter { story in
                        let categories = genreViewModel.extractCategories(from: story.genre)
                        return categories.contains(category)
                    }, id: \.id) { story in
                        NavigationLink(destination: StoryViewGenre(
                            imageUrl: story.url ?? "",
                            title: story.title,
                            genre: story.genre,
                            synopsis: story.synopsis ?? "",
                            story: story.story,
                            currentIndex: viewModel.stories.firstIndex(where: { $0.id == story.id }) ?? 0,
                            selectedStoryIndex: .constant(0),
                            viewModel: viewModel
                        )) {
                            GeometryReader { geometry in
                                ZStack {
                                    // AsyncImage for image loading
                                    AsyncImage(url: URL(string: story.url ?? "")) { phase in
                                        switch phase {
                                        case .empty:
                                            Color.gray
                                                .frame(width: geometry.size.width + 5, height: 200)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: geometry.size.width + 5, height: 200)
                                                .clipped()
                                        case .failure:
                                            Color.gray
                                                .frame(width: geometry.size.width + 5, height: 200)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    
                                    // Title Overlay at the Bottom
                                    VStack {
                                        Spacer()
                                        Text(story.title)
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
                            .frame(height: 200) // Set a fixed height for the container
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle(category)
    }
}










//struct GenreView: View {
//    @EnvironmentObject var storyViewModel: StoryViewModel
//    @StateObject private var genreViewModel = GenreViewModel()
//    
//    var body: some View {
//        ZStack {
//            Color.black.edgesIgnoringSafeArea(.all)
//            ScrollView {
//                VStack(spacing: 20) {
//                    // Iterate over the grouped genres
//                    ForEach(genreViewModel.genres.keys.sorted(), id: \.self) { category in
//                        NavigationLink(destination: GenreDetailView(category: category)) {
//                            Text(category)
//                                .font(.custom("Futura", size: 24))
//                                .fontWeight(.heavy)
//                                .foregroundColor(Color(hex: "#de9590"))
////                                .shadow(color: Color(hex: "#275faa").opacity(1), radius: 0, x: 2, y: 2) // Shadow
//                                .padding()
//                                .frame(maxWidth: .infinity)
//                                .background(Color.black)
//                                .cornerRadius(10)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 10)
//                                        .stroke(Color(hex: "#275faa"), lineWidth: 2)
//                                )
//                        }
//                    }
//                }
//                .padding()
//            }
//        }
//        .onAppear {
//            genreViewModel.fetchGenres(from: storyViewModel.stories)
//        }
//    }
//}
//
//
//
//
//
//
//
//
//
//struct GenreDetailView: View {
//    var category: String
//    @EnvironmentObject var viewModel: StoryViewModel
//    
//    var body: some View {
//        ZStack {
//            Color.black.edgesIgnoringSafeArea(.all)
//            ScrollView {
//                LazyVGrid(columns: [
//                    GridItem(.flexible()),
//                    GridItem(.flexible()),
//                    GridItem(.flexible())
//                ], spacing: 3) {
//                    // Filter stories by the selected category
//                    ForEach(viewModel.stories.filter { $0.genre.hasPrefix(category) }, id: \.id) { story in
//                        NavigationLink(destination: StoryView(
//                            imageUrl: story.url ?? "",
//                            title: story.title,
//                            genre: story.genre,
//                            synopsis: story.synopsis ?? "",
//                            story: story.story,
//                            currentIndex: viewModel.stories.firstIndex(where: { $0.id == story.id }) ?? 0,
//                            selectedStoryIndex: .constant(0),
//                            viewModel: viewModel
//                        )) {
//                            ZStack {
//                                AsyncImage(url: URL(string: story.url ?? "")) { phase in
//                                    switch phase {
//                                    case .empty:
//                                        Color.gray
//                                            .frame(width: UIScreen.main.bounds.width / 3, height: 200)
//                                    case .success(let image):
//                                        image
//                                            .resizable()
//                                            .scaledToFill()
//                                            .frame(width: UIScreen.main.bounds.width / 3, height: 200)
//                                            .clipped()
//                                    case .failure:
//                                        Color.gray
//                                            .frame(width: UIScreen.main.bounds.width / 3, height: 200)
//                                    @unknown default:
//                                        EmptyView()
//                                    }
//                                }
//                                
//                                VStack {
//                                    Spacer()
//                                    Text(story.title)
//                                        .font(.custom("AvenirNext-Bold", size: 14))
//                                        .lineLimit(8)
//                                        .foregroundColor(.white)
//                                        .shadow(color: .black, radius: 2, x: 1, y: 1)
//                                        .padding([.bottom, .leading], 10)
//                                        .frame(maxWidth: .infinity, alignment: .leading)
//                                        .multilineTextAlignment(.leading)
//                                }
//                            }
//                        }
//                    }
//                }
//                .padding(.top, 20)
//            }
//        }
//        .navigationTitle(category)
//    }
//}










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
    
    // State for subscription
    @EnvironmentObject var storeManager: StoreManager  // Shared instance
    
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
                        
                        //                        if storeManager.isSubscribed {
                        //                            restoreSubscriptionView
                        //                        }
                        
                        titleView
                        genreView
                        synopsisView
                        storyParagraphsView
                        
                        if !storeManager.isSubscribed {
                            subscriptionView
                        }
                        
                        additionalStoryParagraphsView
                        Spacer()
                    }
                    .padding(.top)
                    .padding(.bottom, 300)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    nextStoryButton
                }
            }
            .padding([.top, .trailing], 16)
        }
        .navigationTitle("")
        .navigationBarHidden(false)
        .gesture(dragGesture)
    }
    
    
    private var titleView: some View {
        Text(title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.leading, 20)
    }
    
    private var genreView: some View {
        Text(genre)
            .font(.title2)
            .foregroundColor(.white.opacity(0.8))
            .padding(.leading, 20)
    }
    
    private var synopsisView: some View {
        Text(synopsis)
            .font(.body)
            .foregroundColor(.white.opacity(0.8))
            .padding(.leading, 20)
            .padding(.top, 4)
            .italic()
    }
    
    private var storyParagraphsView: some View {
        ForEach(0..<min(paragraphs.count, 3), id: \.self) { index in
            Text(paragraphs[index])
                .font(.system(size: 22))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.leading, 20)
                .padding(.trailing, 0)
                .padding(.top, 10)
                .lineSpacing(0)
        }
    }
    
    private var subscriptionView: some View {
        VStack {
            // Check if the user is eligible for the free trial
             if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }),
                let introductoryPrice = product.introductoryPrice {
                 
                 Text("7-Day Free Trial")
                     .font(.largeTitle)
                     .fontWeight(.bold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 20)
                 
                 Text("Then \(introductoryPrice.priceLocale.currencySymbol ?? "$")\(product.price)/month")
                     .font(.title2)
                     .fontWeight(.semibold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 5)
                 
                 // Additional description for the free trial
                 Text("You'll get full access to all stories for 7 days. After the trial, your subscription will automatically renew for \(introductoryPrice.priceLocale.currencySymbol ?? "$")\(product.price)/month unless canceled.")
                     .font(.subheadline)
                     .foregroundColor(.white.opacity(0.8))
                     .multilineTextAlignment(.center)
                     .padding(.horizontal, 20)
                     .padding(.top, 10)
                 
                 Text("To avoid charges, cancel anytime before the trial ends in your Apple ID settings.")
                     .font(.footnote)
                     .foregroundColor(.white.opacity(0.8))
                     .multilineTextAlignment(.center)
                     .padding(.horizontal, 20)
                     .padding(.top, 5)
                 
                 Button(action: {
                     if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }) {
                         storeManager.purchase(product: product)
                     }
                 }) {
                     Text("Start Free Trial")
                         .font(.headline)
                         .foregroundColor(.white)
                         .padding()
                         .background(Color.blue)
                         .cornerRadius(10)
                         .padding(.top, 10)
                 }
                 
             } else {
                 Text("Subscribe for Full Access")
                     .font(.largeTitle)
                     .fontWeight(.bold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 20)
                     .multilineTextAlignment(.center)
                 
                 Text("$9.99/month")
                     .font(.title2)
                     .fontWeight(.semibold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 5)
                 
                 Button(action: {
                     if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }) {
                         storeManager.purchase(product: product)
                     }
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
            
            Text("Get unlimited access to all stories.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.bottom, 0)
            
            Text("Cancel anytime.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 0)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var additionalStoryParagraphsView: some View {
        ForEach(3..<paragraphs.count, id: \.self) { index in
            Text(paragraphs[index])
                .font(.system(size: 22))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.leading, 20)
                .padding(.trailing, 0)
                .padding(.top, 10)
                .lineSpacing(0)
                .blur(radius: storeManager.isSubscribed ? 0 : 5) // Remove blur if subscribed
        }
    }
    
    private var nextStoryButton: some View {
        NavigationLink(
            destination: StoryView(
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
                
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.blue)
        }
    }
    
    private var dragGesture: some Gesture {
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
    }
}










struct StoryViewDate: View {
    var imageUrl: String
    var title: String
    var genre: String
    var synopsis: String
    var story: String
    
    var batchIndex: Int
    var storyIndex: Int
    @Binding var selectedStoryIndex: Int?
    var viewModel: NewViewModel  // Receive viewModel
    
    @Environment(\.presentationMode) var presentationMode
    @State private var dragAmount: CGFloat = 0
    
    // State for manual navigation
    @State private var navigateToNext = false
    @State private var showPopup = false // State for showing the popup
    @State private var scrollOffset: CGFloat = 0
    
    // State for subscription
    @EnvironmentObject var storeManager: StoreManager  // Shared instance
    
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
                        
                        
                        titleView
                        genreView
                        synopsisView
                        storyParagraphsView
                        
                        if !storeManager.isSubscribed {
                            subscriptionView
                        }
                        
                        additionalStoryParagraphsView
                        Spacer()
                    }
                    .padding(.top)
                    .padding(.bottom, 300)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    nextStoryButton
                }
            }
            .padding([.top, .trailing], 16)
        }
        .navigationTitle("")
        .navigationBarHidden(false)
        .gesture(dragGesture)
    }

    // ... other views ...
    private var titleView: some View {
        Text(title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.leading, 20)
    }
    
    private var genreView: some View {
        Text(genre)
            .font(.title2)
            .foregroundColor(.white.opacity(0.8))
            .padding(.leading, 20)
    }
    
    private var synopsisView: some View {
        Text(synopsis)
            .font(.body)
            .foregroundColor(.white.opacity(0.8))
            .padding(.leading, 20)
            .padding(.top, 4)
            .italic()
    }
    
    private var storyParagraphsView: some View {
        ForEach(0..<min(paragraphs.count, 3), id: \.self) { index in
            Text(paragraphs[index])
                .font(.system(size: 22))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.leading, 20)
                .padding(.trailing, 0)
                .padding(.top, 10)
                .lineSpacing(0)
        }
    }
    
    private var subscriptionView: some View {
        VStack {
            // Check if the user is eligible for the free trial
             if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }),
                let introductoryPrice = product.introductoryPrice {
                 
                 Text("7-Day Free Trial")
                     .font(.largeTitle)
                     .fontWeight(.bold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 20)
                 
                 Text("Then \(introductoryPrice.priceLocale.currencySymbol ?? "$")\(product.price)/month")
                     .font(.title2)
                     .fontWeight(.semibold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 5)
                 
                 // Additional description for the free trial
                 Text("You'll get full access to all stories for 7 days. After the trial, your subscription will automatically renew for \(introductoryPrice.priceLocale.currencySymbol ?? "$")\(product.price)/month unless canceled.")
                     .font(.subheadline)
                     .foregroundColor(.white.opacity(0.8))
                     .multilineTextAlignment(.center)
                     .padding(.horizontal, 20)
                     .padding(.top, 10)
                 
                 Text("To avoid charges, cancel anytime before the trial ends in your Apple ID settings.")
                     .font(.footnote)
                     .foregroundColor(.white.opacity(0.8))
                     .multilineTextAlignment(.center)
                     .padding(.horizontal, 20)
                     .padding(.top, 5)
                 
                 Button(action: {
                     if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }) {
                         storeManager.purchase(product: product)
                     }
                 }) {
                     Text("Start Free Trial")
                         .font(.headline)
                         .foregroundColor(.white)
                         .padding()
                         .background(Color.blue)
                         .cornerRadius(10)
                         .padding(.top, 10)
                 }
                 
             } else {
                 Text("Subscribe for Full Access")
                     .font(.largeTitle)
                     .fontWeight(.bold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 20)
                     .multilineTextAlignment(.center)
                 
                 Text("$9.99/month")
                     .font(.title2)
                     .fontWeight(.semibold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 5)
                 
                 Button(action: {
                     if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }) {
                         storeManager.purchase(product: product)
                     }
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
            
            Text("Get unlimited access to all stories.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.bottom, 0)
            
            Text("Cancel anytime.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 0)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var additionalStoryParagraphsView: some View {
        ForEach(3..<paragraphs.count, id: \.self) { index in
            Text(paragraphs[index])
                .font(.system(size: 22))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.leading, 20)
                .padding(.trailing, 0)
                .padding(.top, 10)
                .lineSpacing(0)
                .blur(radius: storeManager.isSubscribed ? 0 : 5) // Remove blur if subscribed
        }
    }

    private var nextStoryButton: some View {
        let flattenedStories = viewModel.dateStories.flatMap { $0.stories }
        
        if flattenedStories.isEmpty {
            return AnyView(
                Text("No more stories available")
                    .foregroundColor(.gray)
            )
        } else {
            let nextBatchIndex: Int
            let nextStoryIndex: Int
            
            if storyIndex + 1 < viewModel.dateStories[batchIndex].stories.count {
                nextBatchIndex = batchIndex
                nextStoryIndex = storyIndex + 1
            } else if batchIndex + 1 < viewModel.dateStories.count {
                nextBatchIndex = batchIndex + 1
                nextStoryIndex = 0
            } else {
                nextBatchIndex = 0
                nextStoryIndex = 0
            }
            
            let nextStory = viewModel.dateStories[nextBatchIndex].stories[nextStoryIndex]
            
            return AnyView(
                NavigationLink(
                    destination: StoryViewDate(
                        imageUrl: nextStory.url ?? "",
                        title: nextStory.title,
                        genre: nextStory.genre,
                        synopsis: nextStory.synopsis ?? "",
                        story: nextStory.story,
                        batchIndex: nextBatchIndex,
                        storyIndex: nextStoryIndex,
                        selectedStoryIndex: $selectedStoryIndex,
                        viewModel: viewModel
                    ),
                    isActive: $navigateToNext
                ) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.blue)
                }
            )
        }
    }
    
    // ... other code ...
    private var dragGesture: some Gesture {
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
    }
}









struct StoryViewGenre: View {
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
    
    // State for subscription
    @EnvironmentObject var storeManager: StoreManager  // Shared instance
    
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
                        
                        //                        if storeManager.isSubscribed {
                        //                            restoreSubscriptionView
                        //                        }
                        
                        titleView
                        genreView
                        synopsisView
                        storyParagraphsView
                        
                        if !storeManager.isSubscribed {
                            subscriptionView
                        }
                        
                        additionalStoryParagraphsView
                        Spacer()
                    }
                    .padding(.top)
                    .padding(.bottom, 300)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    nextStoryButton
//                }
//            }
            .padding([.top, .trailing], 16)
        }
        .navigationTitle("")
        .navigationBarHidden(false)
        .gesture(dragGesture)
    }
    
    
    private var titleView: some View {
        Text(title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.leading, 20)
    }
    
    private var genreView: some View {
        Text(genre)
            .font(.title2)
            .foregroundColor(.white.opacity(0.8))
            .padding(.leading, 20)
    }
    
    private var synopsisView: some View {
        Text(synopsis)
            .font(.body)
            .foregroundColor(.white.opacity(0.8))
            .padding(.leading, 20)
            .padding(.top, 4)
            .italic()
    }
    
    private var storyParagraphsView: some View {
        ForEach(0..<min(paragraphs.count, 3), id: \.self) { index in
            Text(paragraphs[index])
                .font(.system(size: 22))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.leading, 20)
                .padding(.trailing, 0)
                .padding(.top, 10)
                .lineSpacing(0)
        }
    }
    
    private var subscriptionView: some View {
        VStack {
            // Check if the user is eligible for the free trial
             if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }),
                let introductoryPrice = product.introductoryPrice {
                 
                 Text("7-Day Free Trial")
                     .font(.largeTitle)
                     .fontWeight(.bold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 20)
                 
                 Text("Then \(introductoryPrice.priceLocale.currencySymbol ?? "$")\(product.price)/month")
                     .font(.title2)
                     .fontWeight(.semibold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 5)
                 
                 // Additional description for the free trial
                 Text("You'll get full access to all stories for 7 days. After the trial, your subscription will automatically renew for \(introductoryPrice.priceLocale.currencySymbol ?? "$")\(product.price)/month unless canceled.")
                     .font(.subheadline)
                     .foregroundColor(.white.opacity(0.8))
                     .multilineTextAlignment(.center)
                     .padding(.horizontal, 20)
                     .padding(.top, 10)
                 
                 Text("To avoid charges, cancel anytime before the trial ends in your Apple ID settings.")
                     .font(.footnote)
                     .foregroundColor(.white.opacity(0.8))
                     .multilineTextAlignment(.center)
                     .padding(.horizontal, 20)
                     .padding(.top, 5)
                 
                 Button(action: {
                     if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }) {
                         storeManager.purchase(product: product)
                     }
                 }) {
                     Text("Start Free Trial")
                         .font(.headline)
                         .foregroundColor(.white)
                         .padding()
                         .background(Color.blue)
                         .cornerRadius(10)
                         .padding(.top, 10)
                 }
                 
             } else {
                 Text("Subscribe for Full Access")
                     .font(.largeTitle)
                     .fontWeight(.bold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 20)
                     .multilineTextAlignment(.center)
                 
                 Text("$9.99/month")
                     .font(.title2)
                     .fontWeight(.semibold)
                     .foregroundColor(.white)
                     .padding(.horizontal, 20)
                     .padding(.top, 5)
                 
                 Button(action: {
                     if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }) {
                         storeManager.purchase(product: product)
                     }
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
            
            Text("Get unlimited access to all stories.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.bottom, 0)
            
            Text("Cancel anytime.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.top, 0)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var additionalStoryParagraphsView: some View {
        ForEach(3..<paragraphs.count, id: \.self) { index in
            Text(paragraphs[index])
                .font(.system(size: 22))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.leading, 20)
                .padding(.trailing, 0)
                .padding(.top, 10)
                .lineSpacing(0)
                .blur(radius: storeManager.isSubscribed ? 0 : 5) // Remove blur if subscribed
        }
    }
    
//    private var nextStoryButton: some View {
//        NavigationLink(
//            destination: StoryViewGenre(
//                imageUrl: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].url ?? "",
//                title: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].title,
//                genre: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].genre,
//                synopsis: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].synopsis ?? "",
//                story: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].story,
//                currentIndex: (currentIndex + 1) % viewModel.stories.count,
//                selectedStoryIndex: $selectedStoryIndex,
//                viewModel: viewModel
//            ),
//            isActive: $navigateToNext
//        ) {
//            HStack(spacing: 4) {
//                
//                Image(systemName: "chevron.right")
//            }
//            .foregroundColor(.blue)
//        }
//    }
    
    private var dragGesture: some Gesture {
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
    }
}















struct RandomView: View {
    @EnvironmentObject var viewModel: StoryViewModel
    @State private var randomStory: Story?
    @Binding var selectedTab: Int
    
    // State for subscription
    @EnvironmentObject var storeManager: StoreManager  // Shared instance
    
    @State private var dragAmount: CGFloat = 0
    @State private var navigateToNext = false
    @State private var showModal = false
    
    // Split the story into paragraphs
    private var paragraphs: [String] {
        guard let story = randomStory else { return [] }
        return story.story.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let story = randomStory {
                VStack {
                    if !storeManager.isSubscribed {
                        HStack {
                            Spacer()
                            Button(action: {
                                showModal.toggle()  // Show the modal when button is tapped
                            }) {
                                if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }),
                                   let introductoryPrice = product.introductoryPrice {
                                    Text("7-Day Free Trial")
                                        .font(.custom("Futura", size: 15))
                                        .fontWeight(.regular)
                                        .foregroundColor(.white)
                                        .padding(.top, 20)
                                        .padding(.trailing, 20)
                                        .padding(.bottom, 10)
                                }else{
                                    Text("Subscribe Now")
                                        .font(.custom("Futura", size: 15))
                                        .fontWeight(.regular)
                                        .foregroundColor(.white)
                                        .padding(.top, 20)
                                        .padding(.trailing, 20)
                                        .padding(.bottom, 10)
                                }
                            }
                        }
                    }
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
                                .padding(.leading, 20)
                                .padding(.trailing, 0)
                            
                            
                            Text(story.genre)
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 20) // Add padding to the left
                                .padding(.trailing, 0) // Remove padding on the right
                            
                            
                            Text(story.synopsis ?? "")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.leading, 20) // Add padding to the left
                                .padding(.trailing, 0) // Remove padding on the right
                            
                                .padding(.top, 4)
                                .italic()
                            
                            
                            ForEach(0..<min(paragraphs.count, 3), id: \.self) { index in
                                Text(paragraphs[index])
                                    .font(.system(size: 22))
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.leading, 20)
                                    .padding(.trailing, 0)
                                    .padding(.top, 10)
                                    .lineSpacing(0)
                            }
                            
                            if !storeManager.isSubscribed {
                                VStack {
                                    // Check if the user is eligible for the free trial
                                     if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }),
                                        let introductoryPrice = product.introductoryPrice {
                                         
                                         Text("7-Day Free Trial")
                                             .font(.largeTitle)
                                             .fontWeight(.bold)
                                             .foregroundColor(.white)
                                             .padding(.horizontal, 20)
                                             .padding(.top, 20)
                                         
                                         Text("Then \(introductoryPrice.priceLocale.currencySymbol ?? "$")\(product.price)/month")
                                             .font(.title2)
                                             .fontWeight(.semibold)
                                             .foregroundColor(.white)
                                             .padding(.horizontal, 20)
                                             .padding(.top, 5)
                                         
                                         // Additional description for the free trial
                                         Text("You'll get full access to all stories for 7 days. After the trial, your subscription will automatically renew for \(introductoryPrice.priceLocale.currencySymbol ?? "$")\(product.price)/month unless canceled.")
                                             .font(.subheadline)
                                             .foregroundColor(.white.opacity(0.8))
                                             .multilineTextAlignment(.center)
                                             .padding(.horizontal, 20)
                                             .padding(.top, 10)
                                         
                                         Text("To avoid charges, cancel anytime before the trial ends in your Apple ID settings.")
                                             .font(.footnote)
                                             .foregroundColor(.white.opacity(0.8))
                                             .multilineTextAlignment(.center)
                                             .padding(.horizontal, 20)
                                             .padding(.top, 5)
                                         
                                         Button(action: {
                                             if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }) {
                                                 storeManager.purchase(product: product)
                                             }
                                         }) {
                                             Text("Start Free Trial")
                                                 .font(.headline)
                                                 .foregroundColor(.white)
                                                 .padding()
                                                 .background(Color.blue)
                                                 .cornerRadius(10)
                                                 .padding(.top, 10)
                                         }
                                         
                                     } else {
                                         Text("Subscribe for Full Access")
                                             .font(.largeTitle)
                                             .fontWeight(.bold)
                                             .foregroundColor(.white)
                                             .padding(.horizontal, 20)
                                             .padding(.top, 20)
                                             .multilineTextAlignment(.center)
                                         
                                         Text("$9.99/month")
                                             .font(.title2)
                                             .fontWeight(.semibold)
                                             .foregroundColor(.white)
                                             .padding(.horizontal, 20)
                                             .padding(.top, 5)
                                         
                                         Button(action: {
                                             if let product = storeManager.products.first(where: { $0.productIdentifier == "storytopia_monthly_subscription" }) {
                                                 storeManager.purchase(product: product)
                                             }
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
                                    
                                    Text("Get unlimited access to all stories.")
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 10)
                                        .padding(.bottom, 0)
                                    
                                    Text("Cancel anytime.")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 0)
                                }
                                .padding(.top, 20)
                                .padding(.bottom, 30)
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            
                            
                            ForEach(3..<paragraphs.count, id: \.self) { index in
                                Text(paragraphs[index])
                                    .font(.system(size: 22))
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.leading, 20)
                                    .padding(.trailing, 0)
                                    .padding(.top, 10)
                                    .lineSpacing(0)
                                    .blur(radius: storeManager.isSubscribed ? 0 : 5) // Remove blur if subscribed
                            }
                            
                            
                        }
                        .padding()
                        .padding(.bottom, 300)
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
                        HStack(spacing: 8) { // Add spacing between the icon and the text
                            
                            Text("Shuffle")
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Image(systemName: "chevron.right") // Shuffle icon
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            
                        }
                        .padding()
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                    }
                    .padding(.bottom, 20) // Add some bottom padding for the button
                    .padding(.trailing, 20) // Add some trailing padding to place it on the right
                }
            }
            // Show the SubscriptionModal if showModal is true
            if showModal {
                SubscriptionModal(showModal: $showModal)
                    .transition(.move(edge: .bottom))
                    .zIndex(1) // Ensure the modal appears above the main content
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
        .onAppear {
            viewModel.fetchStories()
        }
    }
    // Function to load a random story
    private func loadRandomStory() {
        randomStory = viewModel.stories.randomElement()
    }
}




















//struct RandomView: View {
//    @EnvironmentObject var viewModel: StoryViewModel
//    @State private var randomStory: Story?
//    @Binding var selectedTab: Int
//
//    // State for subscription
//    @EnvironmentObject var storeManager: StoreManager  // Shared instance
//
//    @State private var dragAmount: CGFloat = 0
//    @State private var navigateToNext = false
//
//    var body: some View {
//        ZStack {
//            Color.black.edgesIgnoringSafeArea(.all)
//
//            if let story = randomStory {
//                VStack {
//                    // Display the story content
//                    ScrollView {
//                        VStack(alignment: .leading) {
//                            AsyncImage(url: URL(string: story.url ?? "")) { phase in
//                                switch phase {
//                                case .empty: Color.gray.frame(height: 300)
//                                case .success(let image): image.resizable().scaledToFit().frame(maxWidth: .infinity)
//                                case .failure: Color.gray.frame(height: 300)
//                                @unknown default: EmptyView()
//                                }
//                            }
//
//                            Text(story.title)
//                                .font(.largeTitle)
//                                .fontWeight(.bold)
//                                .foregroundColor(.white)
//                                .padding(.leading, 20)
//                                .padding(.trailing, 0)
//
//
//                            Text(story.genre)
//                                .font(.title2)
//                                .foregroundColor(.white.opacity(0.8))
//                                .padding(.leading, 20) // Add padding to the left
//                                .padding(.trailing, 0) // Remove padding on the right
//
//
//                            Text(story.synopsis ?? "")
//                                .font(.body)
//                                .foregroundColor(.white.opacity(0.8))
//                                .padding(.leading, 20) // Add padding to the left
//                                .padding(.trailing, 0) // Remove padding on the right
//
//                                .padding(.top, 4)
//                                .italic()
//
//                            Text(story.story)
//                                .font(.system(size: 22))
//                                .fontWeight(.medium)
//                                .foregroundColor(.white)
//                                .padding(.leading, 20) // Add padding to the left
//                                .padding(.trailing, 0) // Remove padding on the right
//                                .padding(.top, 0)
//                                .lineSpacing(0)
//                        }
//                        .padding()
//                    }
//
//                    Spacer() // Push everything up to leave space at the bottom
//                }
//            } else if viewModel.stories.isEmpty {
//                ProgressView().progressViewStyle(CircularProgressViewStyle())
//            } else {
//                ProgressView()
//                    .onAppear {
//                        loadRandomStory() // Load a random story when the view appears
//                    }
//            }
//
//            // "Next" Button positioned at the bottom right, above the TabView shuffle button
//            VStack {
//                Spacer() // Push the button to the bottom
//
//                HStack {
//                    Spacer() // Push the button to the right
//                    Button(action: {
//                        loadRandomStory() // Load a new random story when pressed
//                    }) {
//                        HStack(spacing: 8) { // Add spacing between the icon and the text
//
//                            Text("Shuffle")
//                                .font(.system(size: 16))
//                                .fontWeight(.medium)
//                                .foregroundColor(.white)
//
//                            Image(systemName: "chevron.right") // Shuffle icon
//                                .font(.system(size: 14))
//                                .foregroundColor(.white)
//
//                        }
//                        .padding()
//                        .background(Color.blue.opacity(0.7))
//                        .cornerRadius(12)
//                        .shadow(radius: 10)
//                    }
//                    .padding(.bottom, 20) // Add some bottom padding for the button
//                    .padding(.trailing, 20) // Add some trailing padding to place it on the right
//                }
//            }
//        }
//        .gesture(
//                    DragGesture()
//                        .onChanged { value in
//                            dragAmount = value.translation.width
//                        }
//                        .onEnded { value in
//                            // Trigger action only for a left swipe (negative dragAmount)
//                            if dragAmount < -50 {
//                                loadRandomStory()
//                            }
//                        }
//                )
//    }
//
//    // Function to load a random story
//    private func loadRandomStory() {
//        randomStory = viewModel.stories.randomElement()
//    }
//}









//struct NextView: View {
//    var imageUrl: String
//    var title: String
//    var genre: String
//    var synopsis: String
//    var story: String
//
//    var currentIndex: Int
//    @Binding var selectedStoryIndex: Int?
//    var viewModel: StoryViewModel  // Receive viewModel
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
//            VStack {
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
//                            .padding(.leading, 20)
//                            .padding(.trailing, 0)
//
//                        Text(genre)
//                            .font(.title2)
//                            .foregroundColor(.white.opacity(0.8))
//                            .padding(.leading, 20)
//                            .padding(.trailing, 0)
//
//                        Text(synopsis)
//                            .font(.body)
//                            .foregroundColor(.white.opacity(0.8))
//                            .padding(.leading, 20)
//                            .padding(.trailing, 0)
//                            .padding(.top, 4)
//                            .italic()
//
//                        Text(story)
//                            .font(.system(size: 22))
//                            .fontWeight(.medium)
//                            .foregroundColor(.white)
//                            .padding(.leading, 20)
//                            .padding(.trailing, 0)
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
//                        destination: NextView(
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














//struct StoryViewDate: View {
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
//            VStack {
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
//                            .padding(.leading, 20)
//                            .padding(.trailing, 0)
//
//                        Text(genre)
//                            .font(.title2)
//                            .foregroundColor(.white.opacity(0.8))
//                            .padding(.leading, 20)
//                            .padding(.trailing, 0)
//
//                        Text(synopsis)
//                            .font(.body)
//                            .foregroundColor(.white.opacity(0.8))
//                            .padding(.leading, 20)
//                            .padding(.trailing, 0)
//                            .padding(.top, 4)
//                            .italic()
//
//                        Text(story)
//                            .font(.system(size: 22))
//                            .fontWeight(.medium)
//                            .foregroundColor(.white)
//                            .padding(.leading, 20)
//                            .padding(.trailing, 0)
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
////            .toolbar {
////                ToolbarItem(placement: .navigationBarTrailing) {
////                    NavigationLink(
////                        destination: NextViewDate(
////                            imageUrl: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].url ?? "",
////                            title: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].title,
////                            genre: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].genre,
////                            synopsis: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].synopsis ?? "",
////                            story: viewModel.stories[(currentIndex + 1) % viewModel.stories.count].story,
////                            currentIndex: (currentIndex + 1) % viewModel.stories.count,
////                            selectedStoryIndex: $selectedStoryIndex,
////                            viewModel: viewModel
////                        ),
////                        isActive: $navigateToNext
////                    ) {
////                        HStack(spacing: 4) {
////                            Text("Next")
////                            Image(systemName: "chevron.right")
////                        }
////                        .foregroundColor(.blue)
////                    }
////                }
////            }
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






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
