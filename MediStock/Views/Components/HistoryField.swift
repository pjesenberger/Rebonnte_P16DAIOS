//
//  HistoryField.swift
//  MediStock
//
//  Created by Pascal Jesenberger on 05/10/2025.
//

import SwiftUI

struct HistoryField: View {
    let icon: String
    let label: String
    let value: String
    var isLast: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.subheadline)
            
            Text(value)
                .font(.footnote)
        }
        
        if !isLast {
            Divider()
                .padding(.vertical, 4)
        }
    }
}

#Preview {
    VStack {
        HistoryField(
            icon: "person.fill",
            label: "User",
            value: "V0IH4pPyB8QCOQV5BMhfcLbcn5C2"
        )
        
        HistoryField(
            icon: "clock.fill",
            label: "Date",
            value: "05/10/2025, 3:31",
            isLast: true
        )
    }
    .padding()
}
