//import SwiftUI
//
//extension Color {
//    init(hex: String) {
//        // Ensure that the hex string starts with '#' and remove it
//        let hexSanitized = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
//        
//        // If the string is 6 characters long, it's a valid RGB hex code
//        if hexSanitized.count == 6 {
//            let scanner = Scanner(string: hexSanitized)
//            var hexValue: UInt64 = 0
//            
//            // Scan the hex string to get the color components
//            if scanner.scanHexInt64(&hexValue) {
//                let r = Double((hexValue & 0xFF0000) >> 16) / 255.0
//                let g = Double((hexValue & 0x00FF00) >> 8) / 255.0
//                let b = Double(hexValue & 0x0000FF) / 255.0
//                self.init(red: r, green: g, blue: b)
//            } else {
//                self.init(.gray) // Default to gray if invalid hex
//            }
//        } else {
//            self.init(.gray) // Default to gray if invalid hex length
//        }
//    }
//}
//
//// Modify Story to generate an ID if none is provided
//struct Story: Codable, Identifiable {
//    var id: UUID
//    var url: String?
//    let title: String
//    let genre: String
//    var synopsis: String?
//    let story: String
//    var hasLoadedURL: Bool = false // Default to not loaded
//
//    enum CodingKeys: String, CodingKey {
//        case url
//        case title
//        case genre
//        case synopsis
//        case story
//    }
//
//    // Use a custom initializer to assign a UUID
//    init(title: String, genre: String, synopsis: String, url: String, story: String) {
//        self.id = UUID() // Generate a new UUID for each story
//        self.url = url
//        self.title = title
//        self.genre = genre
//        self.synopsis = synopsis
//        self.story = story
//    }
//
//    // Custom decoding to generate id if missing
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.id = UUID() // Generate a new UUID
//        self.url = try container.decode(String.self, forKey: .url)
//        self.title = try container.decode(String.self, forKey: .title)
//        self.genre = try container.decode(String.self, forKey: .genre)
//        self.synopsis = try container.decodeIfPresent(String.self, forKey: .synopsis)
//        self.story = try container.decode(String.self, forKey: .story)
//    }
//}
//
//// ViewModel to Fetch Stories
//class StoryViewModel: ObservableObject {
//    @Published var stories: [Story] = []
//
//    func fetchStories() {
//        guard let url = URL(string: "https://stories-server.vercel.app/stories") else { return }
//
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                print("Error fetching stories: \(error)")
//                return
//            }
//
//            if let data = data {
//                do {
//                    let decodedStories = try JSONDecoder().decode([Story].self, from: data)
//                    DispatchQueue.main.async {
//                        print(decodedStories) // Check if both stories are decoded correctly
//                        self.stories = decodedStories
//                    }
//                } catch {
//                    print("Error decoding JSON: \(error)")
//                }
//            }
//        }.resume()
//    }
//
//    func fetchImageURL(for story: Story) {
//        // Simulate fetching a URL lazily
//        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
//            if let index = self.stories.firstIndex(where: { $0.id == story.id }) {
//                DispatchQueue.main.async {
//                    self.stories[index].url = story.url // Update the URL
//                    self.stories[index].hasLoadedURL = true // Mark as loaded
//                }
//            }
//        }
//    }
//}
//
//struct BottomNavBar: View {
//    var randomAction: () -> Void
//    @Binding var selectedTab: String
//    var body: some View {
//        HStack {
//            Spacer()
//
//            VStack {
//                Image(systemName: selectedTab == "Home" ? "house.fill" : "house")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 20, height: 20)
//                    .foregroundColor(selectedTab == "Home" ? .blue : .white)
//                  Text("Home")
//                      .font(.footnote)
//                      .foregroundColor(selectedTab == "Home" ? .blue : .white)
//              }
////              .onTapGesture {
////                  selectedTab = "All"
////              }
//            
//            Spacer()
//            
//            VStack {
//                Image(systemName: "star") // Replace with appropriate SF Symbol or custom icon
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 20, height: 20)
//                    .foregroundColor(.white)
//                Text("New")
//                    .font(.footnote)
//                    .foregroundColor(.white)
//            }
//            Spacer()
//
//            VStack {
//                Image(systemName: "rectangle.grid.2x2")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 20, height: 20)
//                    .foregroundColor(.white)
//                Text("Genre")
//                    .font(.footnote)
//                    .foregroundColor(.white)
//            }
//            Spacer()
//            
//            VStack {
//                Image(systemName: "shuffle")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 20, height: 20)
//                    .foregroundColor(.white)
//                Text("Random")
//                    .font(.footnote)
//                    .foregroundColor(.white)
//            }
//            .onTapGesture {
//                randomAction()  // Call the closure when the button is tapped
//            }
//            Spacer()
//        }
//        .padding(.vertical, 8) // Adjust the padding of the entire navbar
//        .background(Color.black)
////        .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 0, y: -2)
//    }
//}
//
//struct ContentView: View {
//    @StateObject private var viewModel = StoryViewModel()
//    @State private var selectedTab: String = "Home"
//    @State private var selectedStory: Story? = nil
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // Background color
//                Color.black
//                    .edgesIgnoringSafeArea(.all)
//
//                VStack {
//                    ScrollView {
//                        VStack {
//                            // Optional Title and Subtitle
//                            Text("STORYTOPIA")
//                                .font(.custom("Futura", size: 40))
//                                .fontWeight(.heavy)
//                                .multilineTextAlignment(.center)
//                                .foregroundColor(Color(hex: "#de9590"))
//                                .padding(.top, 30)
//                                .tracking(5) // Letter spacing
//                                .shadow(color: Color(hex: "#275faa").opacity(1), radius: 0, x: 5, y: 5) // Shadow
//                                .padding(.horizontal, 20)
//                            
//                            VStack {
//                                Text("AI Generated Short Stories")
//                                    .font(.custom("Futura", size: 18))
//                                    .fontWeight(.medium)
//                                    .foregroundColor(.white)
//                                    .padding(.top, 0)
//                                    .multilineTextAlignment(.center)
//                                
//                                Text("New Stories Every Day")
//                                    .font(.custom("Futura", size: 16))
//                                //                                .fontWeight(.medium)
//                                    .foregroundColor(.white)
//                                    .padding(.top, 0)
//                                    .multilineTextAlignment(.center)
//                                
//                                Text("Total Count: \(viewModel.stories.count) Stories") // Dynamic count
//                                    .font(.custom("Futura", size: 14))
//                                    .fontWeight(.light)
//                                    .foregroundColor(.gray)
//                            }
//                            .padding(.top, 0)
//                            
//                            // Lazy Grid for Images
//                            LazyVGrid(columns: [
//                                GridItem(.flexible()),
//                                GridItem(.flexible()),
//                                GridItem(.flexible())
//                            ], spacing: 3) {
//                                ForEach(viewModel.stories) { item in
//                                    NavigationLink(destination: StoryView(
//                                        imageUrl: item.url ?? "",
//                                        title: item.title,
//                                        genre: item.genre,
//                                        synopsis: item.synopsis ?? "",
//                                        story: item.story
//                                    )) {
//                                        ZStack {
//                                            // AsyncImage for image loading
//                                            AsyncImage(url: URL(string: item.url ?? "")) { phase in
//                                                switch phase {
//                                                case .empty:
//                                                    Color.gray
//                                                        .frame(width: UIScreen.main.bounds.width / 3, height: 200)
//                                                case .success(let image):
//                                                    image
//                                                        .resizable()
//                                                        .scaledToFill()
//                                                        .frame(width: UIScreen.main.bounds.width / 3, height: 200)
//                                                        .clipped()
//                                                case .failure:
//                                                    Color.gray
//                                                        .frame(width: UIScreen.main.bounds.width / 3, height: 200)
//                                                @unknown default:
//                                                    EmptyView()
//                                                }
//                                            }
//                                            
//                                            // Title Overlay at the Bottom
//                                            VStack {
//                                                Spacer()
//                                                Text(item.title)
//                                                    .font(.custom("AvenirNext-Bold", size: 14))
//                                                    .lineLimit(8)
//                                                    .foregroundColor(.white)
//                                                    .shadow(color: .black, radius: 2, x: 1, y: 1)
//                                                    .padding([.bottom, .leading], 10)
//                                                    .frame(maxWidth: .infinity, alignment: .leading)
//                                                    .multilineTextAlignment(.leading)
//                                            }
//                                        }
//                                    }
//                                    .onAppear {
//                                        if !item.hasLoadedURL {
//                                            viewModel.fetchImageURL(for: item)
//                                        }
//                                    }
//                                }
//                            }
//                            .padding(.top, 30)
//                        }
//                    }
//                    BottomNavBar(randomAction: {
//                        // Randomly select a story
//                        if !viewModel.stories.isEmpty {
//                            selectedStory = viewModel.stories.randomElement()
//                        }
//                    }, selectedTab: $selectedTab)
//                }
//            }
//            .onAppear {
//                viewModel.fetchStories()
//            }
//            
//            .background(
//                NavigationLink(
//                    destination: StoryView(
//                        imageUrl: selectedStory?.url ?? "",
//                        title: selectedStory?.title ?? "",
//                        genre: selectedStory?.genre ?? "",
//                        synopsis: selectedStory?.synopsis ?? "",
//                        story: selectedStory?.story ?? ""
//                    ),
//                    isActive: Binding(
//                        get: { selectedStory != nil },
//                        set: { _ in selectedStory = nil }
//                    )
//                ) {
//                    EmptyView()
//                }
//                .hidden()
//            )
//            
//        }
//    }
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
