import SwiftUI

struct MainTabView: View {
    @StateObject var medicineStockViewModel = MedicineStockViewModel()
    
    var body: some View {
        TabView {
            AisleListView(viewModel: medicineStockViewModel)
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Aisles")
                }

            AllMedicinesView(viewModel: medicineStockViewModel)
                .tabItem {
                    Image(systemName: "pills.fill")
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
