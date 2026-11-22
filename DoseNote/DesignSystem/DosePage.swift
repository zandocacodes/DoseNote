import SwiftUI

struct DosePage<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16, content: content)
                .frame(maxWidth: 550, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
        }
        .background(Color("Paper").ignoresSafeArea())
        .foregroundStyle(Color("Ink"))
        .tint(Color("Forest"))
        .scrollDismissesKeyboard(.interactively)
    }
}
