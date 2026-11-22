import SwiftUI

struct PageHeading: View {
    let title: String
    let subtitle: String

    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 42

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: titleSize, weight: .bold))
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .foregroundStyle(Color("Muted"))
        }
        .padding(.bottom, 20)
    }
}
