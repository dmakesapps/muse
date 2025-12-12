import SwiftUI

struct ProgressView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.museDeepNavy
                    .ignoresSafeArea()
                
                VStack {
                    Text("Progress")
                        .font(.museDisplayLarge())
                        .foregroundColor(.museSoftWhite)
                        .padding()
                    
                    Text("Track your growth & insights")
                        .font(.museSubheadline())
                        .foregroundColor(.museLightGray)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    ProgressView()
}

