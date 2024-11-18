import SwiftUI

struct LocationToggleView: View {
    @Binding var location: Location
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Select Your Location")
                .font(.headline)
                .foregroundColor(.gray)
            
            HStack(spacing: 16) {
                LocationButton(
                    title: "Phase II",
                    isSelected: location == .phIINewCampus,
                    color: .green
                ) {
                    location = .phIINewCampus
                }
                
                LocationButton(
                    title: "Phase I",
                    isSelected: location == .phIParkingLot,
                    color: .blue
                ) {
                    location = .phIParkingLot
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        }
    }
}

struct LocationButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "bus.fill")
                    .foregroundColor(isSelected ? .white : color)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(isSelected ? color : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(8)
        }
    }
}

#Preview {
    LocationToggleView(location: .constant(.phIINewCampus))
} 
