import SwiftUI

struct FramePreference: PreferenceKey {
    static var defaultValue: [Namespace.ID: CGRect] = [:]

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

enum StickyRects: EnvironmentKey {
    static var defaultValue: [Namespace.ID: CGRect]? = nil
}

extension EnvironmentValues {
    var stickyRects: StickyRects.Value {
        get { self[StickyRects.self] }
        set { self[StickyRects.self] = newValue }
    }
}

struct Sticky: ViewModifier {
    @Environment(\.stickyRects) var stickyRects
    @State var frame: CGRect = .zero
    @Namespace private var id

    var isSticking: Bool {
        frame.minY < 0
    }

    var offset: CGFloat {
        guard isSticking else { return 0 }
        guard let stickyRects else {
            print("Warning: Using .sticky() without .useStickyHeaders()")
            return 0
        }
        var o = -frame.minY
        if let other = stickyRects.first(where: { (key, value) in
            key != id && value.minY > frame.minY && value.minY < frame.height

        }) {
            o -= frame.height - other.value.minY
        }
        return o
    }

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .zIndex(isSticking ? .infinity : 0)
            .overlay(GeometryReader { proxy in
                let f = proxy.frame(in: .named("container"))
                Color.clear
                    .onAppear { frame = f }
                    .onChange(of: f) { frame = $0 }
                    .preference(key: FramePreference.self, value: [id: frame])
            })
    }
}

extension View {
    func sticky() -> some View {
        modifier(Sticky())
    }
}

struct UseStickyHeaders: ViewModifier {
    @State private var frames: StickyRects.Value = [:]

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(FramePreference.self, perform: {
                frames = $0
            })
            .environment(\.stickyRects, frames)
    }
}

extension View {
    func useStickyHeaders() -> some View {
        modifier(UseStickyHeaders())
    }
}

struct ContentView: View {
    var body: some View {
        ScrollView {
            contents
        }
//        .useStickyHeaders()
        .coordinateSpace(name: "container")
//        .overlay(alignment: .center) {
//            let str = frames.map {
//                "\(Int($0.minY)) - \(Int($0.height))"
//            }.joined(separator: "\n")
//            Text(str)
//                .foregroundColor(.white)
//                .background(.black)
//        }
    }

    @ViewBuilder var contents: some View {
        Image(systemName: "globe")
            .imageScale(.large)
            .foregroundColor(.accentColor)
            .padding()
        ForEach(0..<50) { ix in
            Text("Heading \(ix)")
                .font(.title)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
                .sticky()
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce ut turpis tempor, porta diam ut, iaculis leo. Phasellus condimentum euismod enim fringilla vulputate. Suspendisse sed quam mattis, suscipit ipsum vel, volutpat quam. Donec sagittis felis nec nulla viverra, et interdum enim sagittis. Nunc egestas scelerisque enim ac feugiat. ")
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
