import SwiftUI

struct ProfileRow<Destination: View>: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconColor: Color? = nil
    var trailing: (() -> AnyView)? = nil
    var onTap: (() -> Void)? = nil
    var destination: (() -> Destination)? = nil

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color? = nil,
        onTap: (() -> Void)? = nil
    ) where Destination == EmptyView {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.onTap = onTap
        self.trailing = nil
        self.destination = nil
    }

    init<Trailing: View>(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
        ,
        onTap: (() -> Void)? = nil
    ) where Destination == EmptyView {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.onTap = onTap
        self.trailing = { AnyView(trailing()) }
        self.destination = nil
    }

    init<Trailing: View>(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.trailing = { AnyView(trailing()) }
        self.destination = destination
        self.onTap = nil
    }

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        iconColor: Color? = nil,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.destination = destination
        self.onTap = nil
        self.trailing = nil
    }

    var body: some View {
        Group {
            if let destination {
                NavigationLink {
                    destination()
                } label: {
                    rowContent
                }
            } else {
                rowContent
                    .onTapGesture {
                        onTap?()
                    }
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor ?? Color.purple600)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.black)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let trailing {
                trailing()
            }

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .contentShape(Rectangle())
        .overlay(
            Divider()
                .padding(.leading, 50),
            alignment: .bottom
        )
    }
}
