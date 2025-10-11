import SwiftUI

struct AisleListView: View {
    @ObservedObject var viewModel = MedicineStockViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.aisles.isEmpty {
                    ProgressView("Loading aisles...")
                } else if let errorMessage = viewModel.errorMessage, viewModel.aisles.isEmpty {
                    VStack(spacing: 20) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button(action: {
                            viewModel.fetchAisles()
                        }) {
                            Text("Retry")
                                .foregroundStyle(Color.white)
                                .padding(12)
                                .padding(.horizontal)
                                .background(Color.green)
                                .cornerRadius(100)
                        }
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
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil && !viewModel.aisles.isEmpty), actions: {
                Button("Retry") {
                    viewModel.fetchAisles()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            }, message: {
                Text(viewModel.errorMessage ?? "")
            })
            .navigationBarTitle("Aisles")
            .navigationBarItems(trailing: Button(action: {
                viewModel.addRandomMedicine(user: "test_user") // Remplacez par l'utilisateur actuel
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
