import SwiftUI

struct StorySwipeView: View {
    var imageUrl: String
    var title: String
    var genre: String
    var synopsis: String
    var story: String

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

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
                    
                    // Add the synopsis here
                    Text(synopsis)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .italic()

                    Text(story)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 0)
                        .lineSpacing(8)

                    Spacer()
                }
                .padding(.top)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(false)
    }
}

struct StorySwipeView_Previews: PreviewProvider {
    static var previews: some View {
        StorySwipeView(
            imageUrl: "https://i.imgur.com/UoPpVKw.jpeg",
            title: "AI Journey: The Girl Who Knew Too Much",
            genre: "Cyberpunk",
            synopsis: "In a future ruled by machines, Kairo the cat must navigate a dangerous world to uncover the truth behind his mysterious origins.",
            story: "In the neon-lit streets of Neo-Celeste, In this world of wires and dreams, Kairo was more than a cat. He was the pulse of something greater, an agent in the quiet war between humanity and the machines that shaped their destiny. And he would continue to walk between the two worlds, his paws leaving no trace in the digital streets."
        )
    }
}
