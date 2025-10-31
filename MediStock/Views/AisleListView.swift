import SwiftUI

struct AisleListView: View {
    @EnvironmentObject var viewModel: MedicineStockViewModel
    @State private var showingAddMedicine = false
    @EnvironmentObject var session: SessionStore

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.aisles.isEmpty {
                    LoadingStateView(message: "Loading aisles...")
                } else if let errorMessage = viewModel.errorMessage, viewModel.aisles.isEmpty {
                    ErrorStateView(errorMessage: errorMessage) {
                        viewModel.fetchAisles()
                    }
                } else {
                    List {
                        ForEach(viewModel.aisles, id: \.self) { aisle in
                            NavigationLink(destination: MedicineListView(viewModel: viewModel, aisle: aisle)) {
                                Text(aisle)
                            }
                        }
                    }
                }
            }
            .errorAlert(
                isPresented: .constant(viewModel.errorMessage != nil && !viewModel.aisles.isEmpty),
                message: viewModel.errorMessage ?? "",
                onRetry: {
                    viewModel.fetchAisles()
                },
                onCancel: {
                    viewModel.errorMessage = nil
                }
            )
            .navigationBarTitle("Aisles")
            .navigationBarItems(trailing: Button(action: {
                showingAddMedicine = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddMedicine) {
                AddMedicineView()
            }
        }
        .onAppear {
            viewModel.fetchAisles()
        }
    }
}

struct AisleListView_Previews: PreviewProvider {
    static var previews: some View {
        AisleListView()
    }
}
