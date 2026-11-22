import SwiftUI

extension View {
    func doseField() -> some View {
        padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color("Muted").opacity(0.45), lineWidth: 1)
            }
    }
}
