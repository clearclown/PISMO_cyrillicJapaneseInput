import SwiftUI

struct HeaderLogoView: View {
    var body: some View {
        Text(verbatim: "Pismo")
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundStyle(Color("IconColor"))
            .accessibilityLabel("Pismo")
    }
}
