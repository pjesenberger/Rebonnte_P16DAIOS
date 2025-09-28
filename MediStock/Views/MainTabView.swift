import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AisleListView()
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Aisles")
                }

            AllMedicinesView()
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("All Medicines")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
