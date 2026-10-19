//
//  BillModel.swift
//  Bill Splitter
//
//  Created by Dian Maisara on 17/10/26.
//

import Foundation

enum RoundingStrategy: String, CaseIterable {
    case none                   // don't round
    case roundUp                // round up so that it's divisible
    case roundToNearestDollar   // round so that each pays an integer amount

    var title: String {
        switch self {
        case .none: return "None"
        case .roundUp: return "Round Up"
        case .roundToNearestDollar: return "Nearest Dollar"
        }
    }
}

struct BillModel {
    var billAmount: Decimal
    var gstEnabled: Bool
    var serviceEnabled: Bool
    var serviceRate: Decimal = Decimal(10) / 100   // 10%
    var gstRate: Decimal = Decimal(9) / 100        // 9%
    var partySize: Int
    var roundingStrategy: RoundingStrategy

    var servicePercent: Int { NSDecimalNumber(decimal: serviceRate * 100).intValue }
    var gstPercent: Int { NSDecimalNumber(decimal: gstRate * 100).intValue }

    var serviceChargeAmount: Decimal {
        serviceEnabled ? billAmount * serviceRate : 0
    }

    /// In Singapore, GST is charged on the bill *plus* service charge.
    var gstAmount: Decimal {
        gstEnabled ? (billAmount + serviceChargeAmount) * gstRate : 0
    }

    var totalAmount: Decimal {
        billAmount + serviceChargeAmount + gstAmount
    }

    // each person pays after rounding strategy applied
    var displayPerPerson: Decimal {
        let rawPerPerson = totalAmount / Decimal(safePartySize)
        switch roundingStrategy {
        case .none:
            return Self.rounded(rawPerPerson, scale: 2, mode: .plain)
        case .roundUp:
            return Self.rounded(rawPerPerson, scale: 2, mode: .up)
        case .roundToNearestDollar:
            return Self.rounded(rawPerPerson, scale: 0, mode: .plain)
        }
    }

    //  total after rounding
    var displayTotal: Decimal {
        switch roundingStrategy {
        case .none:
            return totalAmount
        case .roundUp, .roundToNearestDollar:
            return displayPerPerson * Decimal(safePartySize)
        }
    }

    private var safePartySize: Int { max(partySize, 1) }

    private static func rounded(_ value: Decimal, scale: Int, mode: NSDecimalNumber.RoundingMode) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, scale, mode)
        return output
    }
}
