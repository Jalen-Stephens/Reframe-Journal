import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension View {
    @MainActor
    func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    func keyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    Task { @MainActor in
                        dismissKeyboard()
                    }
                }
            }
        }
    }
}
