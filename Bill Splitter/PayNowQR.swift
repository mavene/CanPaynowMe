//
//  PayNowQR.swift
//  Bill Splitter
//
//  Created by Dian Maisara on 17/10/26.
//

import UIKit
import CoreImage.CIFilterBuiltins // rendering of QR code

enum PayNowQR {

    // function that gets called by ViewController
    static func image(mobileNumber: String, amount: Decimal, reference: String = "CanPaynowMe") -> UIImage? {
        guard let proxy = normalisedMobile(mobileNumber) else { return nil } // make sure we accept various phone numbers
        let payload = payload(proxy: proxy, amount: amount, reference: reference) // call payload  below
        return qrImage(from: payload) // return generated image from payload
    }

    // paynow payload - https://github.com/poonchuanan/Python-PayNow-QR-Code-Generator as example
    // ref -  https://www.linkedin.com/pulse/decoding-emv-qr-codemerchant-standard-yogesh-chander-3mvqc
    // field + length + value
    private static func payload(proxy: String, amount: Decimal, reference: String) -> String {
        let merchantAccount =
            field("00", "SG.PAYNOW") +    // shd read out 0009SG.PAYNOW
            field("01", "0") +            // proxy type: 0 = mobile
            field("02", proxy) +          // e.g. +6591234567
            field("03", "0")              // amount not editable

        var body =
            field("00", "01") +           // payload format (MPM)
            field("01", "12") +           // dynamic QR (has an amount)
            field("26", merchantAccount) + // all the merchant info above which is basically paynow
            field("52", "0000") +         // merchant category not needed so put blank
            field("53", "702") +          // SGD currency used
            field("54", amountString(amount)) + // transaction amount
            field("58", "SG") +           // country code
            field("59", "NA") +           // merchant name which is us so no need NA
            field("60", "Singapore") +    // merchant city which is a local SG...
            field("62", field("01", reference)) // additional info like reference which is just the app name

        body += "6304" // crc tag and length (4 hex digit only)
        return body + String(format: "%04X", crc16(body)) // add the computed checksum at the end
    }

    // TLV helper (tag, length, value) -> called above in payload
    private static func field(_ id: String, _ value: String) -> String {
        id + String(format: "%02d", value.utf8.count) + value
    }

    // help to format the amount in payload
    private static func amountString(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0.00"
    }

    // accepts "91234567", "+65 9123 4567", "6591234567" and returns "+6591234567".
    private static func normalisedMobile(_ input: String) -> String? {
        let digits = input.filter(\.isNumber)
        switch digits.count {
        case 8: return "+65" + digits
        case 10 where digits.hasPrefix("65"): return "+" + digits
        default: return nil
        }
    }

    // CRC-16/CCITT-FALSE required by the EMVCo QR spec.
    private static func crc16(_ string: String) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        for byte in string.utf8 {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1
            }
        }
        return crc
    }

    
    // render qr code
    private static func qrImage(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M" // medium data loss

        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
