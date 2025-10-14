import SwiftUI

struct AisleListView: View {
    @ObservedObject var viewModel = MedicineStockViewModel()

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
                            NavigationLink(destination: MedicineListView(aisle: aisle)) {
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
                viewModel.addRandomMedicine(user: "test_user")
            }) {
                Image(systemName: "plus")
            })
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
