import SwiftUI

/// Historical entry point for the profile area.
/// Some Xcode project configurations still list this file as a build input,
/// so keep it to avoid "Build input file cannot be found".
struct ProfileView: View {
    var body: some View {
        AccountView()
    }
}

#Preview {
    ProfileView()
}


