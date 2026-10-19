//
//  ViewController.swift
//  Bill Splitter
//
//  Created by Dian Maisara on 16/10/26.
//

import UIKit

// Foodpanda color: #FF2B85 (magenta) + #FFFFFF (white)

class ViewController: UIViewController, UITextFieldDelegate {

    private static let brandColor = UIColor(red: 255/255, green: 43/255, blue: 133/255, alpha: 1.0)
    private static let softPink = UIColor(red: 1, green: 240.0/255, blue: 247.0/255, alpha: 1)

    // list out the different user defaults data
    private enum DefaultsKey {
        static let payNowNumber = "payNowNumber"
        static let serviceEnabled = "serviceEnabled"
        static let gstEnabled = "gstEnabled"
    }

    private var billAmount: Decimal = 0
    private var partySize = 2
    private var roundingStrategy: RoundingStrategy = .none

    private var bill: BillModel {
        BillModel(
            billAmount: billAmount,
            gstEnabled: gstChargeSwitch.isOn,
            serviceEnabled: serviceChargeSwitch.isOn,
            partySize: partySize,
            roundingStrategy: roundingStrategy
        )
    }

    // allow scrolling by using UIScrollView since stuff gets pushed down with the QR code and running totals
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.alwaysBounceVertical = true // rubber band effect
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    // main stack to add elements to
    private let stackView: UIStackView = {
        let parentStack = UIStackView()
        parentStack.axis = .vertical
        parentStack.alignment = .fill
        parentStack.spacing = 30
        parentStack.translatesAutoresizingMaskIntoConstraints = false
        return parentStack
    }()

    // this is for the final calculation + QR
    private let resultStackView: UIStackView = {
        let resultStack = UIStackView()
        resultStack.axis = .vertical
        resultStack.alignment = .fill
        resultStack.spacing = 12
        resultStack.translatesAutoresizingMaskIntoConstraints = false
        return resultStack
    }()

    
    // Setup overall app name
    private let appLabel: UILabel = {
        let label = UILabel()
        label.text = "Can Paynow Me?"
        label.font = .systemFont(ofSize: 26)
        label.textColor = ViewController.brandColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    // Setup price field (numeric stuff)
    private let billField: UITextField = {
        let field = UITextField()
        field.attributedPlaceholder = NSAttributedString(
            string: "$ 0.00",
            attributes: [
                .foregroundColor: UIColor(
                    red: 1, green: 43.0/255, blue: 133.0/255, alpha: 0.5
                )
            ]
        )
        field.font = .systemFont(ofSize: 48, weight: .semibold)
        field.textColor = ViewController.brandColor
        field.textAlignment = .center
        field.keyboardType = .decimalPad
        field.backgroundColor = ViewController.softPink
        field.layer.cornerRadius = 32
        field.layer.borderWidth = 1.5
        field.layer.borderColor = UIColor(
            red: 1, green: 43.0/255, blue: 133.0/255, alpha: 0.4
        ).cgColor
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .go
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.translatesAutoresizingMaskIntoConstraints = false
        field.isUserInteractionEnabled = true
        return field
    }()

    private let serviceChargeLabel: UILabel = {
        let label = UILabel()
        label.text = "Service Charge (10%)"
        label.font = .systemFont(ofSize: 22)
        label.textColor = ViewController.brandColor
        label.textAlignment = .left
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let serviceChargeSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = false
        toggle.onTintColor = ViewController.brandColor
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        return toggle
    }()

    // grp the service charge stuff together
    private lazy var serviceChargeRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [serviceChargeLabel, serviceChargeSwitch])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let gstChargeLabel: UILabel = {
        let label = UILabel()
        label.text = "GST (9%)"
        label.font = .systemFont(ofSize: 22)
        label.textColor = ViewController.brandColor
        label.textAlignment = .left
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let gstChargeSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = false
        toggle.onTintColor = ViewController.brandColor
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        return toggle
    }()

    // grp the gst ones together
    private lazy var gstChargeRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [gstChargeLabel, gstChargeSwitch])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let peopleLabel: UILabel = {
        let label = UILabel()
        label.text = "2 people" // default value
        label.font = .systemFont(ofSize: 22, weight: .semibold)
        label.textColor = ViewController.brandColor
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let peopleStepper: UIStepper = {
        let stepper = UIStepper()
        stepper.minimumValue = 1
        stepper.maximumValue = 30
        stepper.value = 2 // default value
        stepper.setContentHuggingPriority(.required, for: .horizontal)
        return stepper
    }()

    // grp the people stepper together
    private lazy var peopleRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [peopleLabel, peopleStepper])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let roundingButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Rounding: None"
        config.baseBackgroundColor = ViewController.brandColor
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    private let payNowField: UITextField = {
        let field = UITextField()
        field.placeholder = "Your PayNow mobile (for the QR)"
        field.font = .systemFont(ofSize: 18)
        field.textColor = ViewController.brandColor
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.backgroundColor = ViewController.softPink
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor(
            red: 1, green: 43.0/255, blue: 133.0/255, alpha: 0.4
        ).cgColor
        field.clearButtonMode = .whileEditing
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    // MARK: - Results card (this whole view gets screenshotted)

    private let resultsContainerView: UIView = {
        let card = UIView()
        card.backgroundColor = ViewController.softPink
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1.5
        card.layer.borderColor = UIColor(
            red: 1, green: 43.0/255, blue: 133.0/255, alpha: 0.4
        ).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }()

    private let subtotalLabel = ViewController.makeResultLabel()
    private let serviceAmountLabel = ViewController.makeResultLabel()
    private let gstAmountLabel = ViewController.makeResultLabel()
    private let totalLabel = ViewController.makeResultLabel(size: 24, color: .systemGreen)
    private let perPersonLabel = ViewController.makeResultLabel(size: 26, color: ViewController.brandColor)

    private let qrImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.magnificationFilter = .nearest
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let qrCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Scan with your banking app to PayNow"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true // until we update with our QR code
        return label
    }()

    private let resetButton: UIButton = {
        var config = UIButton.Configuration.gray()
        config.title = "Reset"
        config.baseForegroundColor = .black
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        return UIButton(configuration: config)
    }()

    private let shareButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Share"
        config.baseBackgroundColor = ViewController.brandColor
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        return UIButton(configuration: config)
    }()

    // grp the reset/share buttons at the bottom
    private lazy var buttonRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [resetButton, shareButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        billField.delegate = self // need to track / monitor

        setupElements()
        setupLayout()
        setupActions()
        loadSavedSettings() // user defaults stuff
        updateResults() // whatever needs to be updated dynamically to UI
    }

    private func setupElements() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.addArrangedSubview(appLabel)
        stackView.addArrangedSubview(billField)
        stackView.addArrangedSubview(serviceChargeRow)
        stackView.addArrangedSubview(gstChargeRow)
        stackView.addArrangedSubview(peopleRow)
        stackView.addArrangedSubview(roundingButton)
        stackView.addArrangedSubview(payNowField)
        stackView.addArrangedSubview(resultsContainerView)
        stackView.addArrangedSubview(buttonRow)

        resultsContainerView.addSubview(resultStackView)
        resultStackView.addArrangedSubview(subtotalLabel)
        resultStackView.addArrangedSubview(serviceAmountLabel)
        resultStackView.addArrangedSubview(gstAmountLabel)
        resultStackView.addArrangedSubview(totalLabel)
        resultStackView.addArrangedSubview(perPersonLabel)
        resultStackView.addArrangedSubview(qrImageView)
        resultStackView.addArrangedSubview(qrCaptionLabel)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 30),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -30),

            billField.heightAnchor.constraint(equalToConstant: 64),
            payNowField.heightAnchor.constraint(equalToConstant: 44),

            resultStackView.topAnchor.constraint(equalTo: resultsContainerView.topAnchor, constant: 20),
            resultStackView.bottomAnchor.constraint(equalTo: resultsContainerView.bottomAnchor, constant: -20),
            resultStackView.leadingAnchor.constraint(equalTo: resultsContainerView.leadingAnchor, constant: 20),
            resultStackView.trailingAnchor.constraint(equalTo: resultsContainerView.trailingAnchor, constant: -20),

            qrImageView.heightAnchor.constraint(equalToConstant: 180),
        ])
    }

    private func setupActions() {
        // tap anywhere to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        // update toggle and update the UI
        serviceChargeSwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            UserDefaults.standard.set(self.serviceChargeSwitch.isOn, forKey: DefaultsKey.serviceEnabled)
            self.updateResults()
        }, for: .valueChanged)

        // ditto...
        gstChargeSwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            UserDefaults.standard.set(self.gstChargeSwitch.isOn, forKey: DefaultsKey.gstEnabled)
            self.updateResults()
        }, for: .valueChanged)

        //
        peopleStepper.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.partySize = Int(self.peopleStepper.value)
            self.refreshPeopleLabel() // update the UI label
            self.updateResults()
        }, for: .valueChanged)

        payNowField.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            UserDefaults.standard.set(self.payNowField.text ?? "", forKey: DefaultsKey.payNowNumber)
            self.updateResults()
        }, for: .editingChanged)

//        roundingButton.showsMenuAsPrimaryAction = true
        refreshRoundingButton()

        resetButton.addAction(UIAction { [weak self] _ in
            self?.resetBill()
        }, for: .touchUpInside)

        shareButton.addAction(UIAction { [weak self] _ in
            self?.shareResults()
        }, for: .touchUpInside)
    }

    private func loadSavedSettings() {
        let defaults = UserDefaults.standard
        serviceChargeSwitch.isOn = defaults.bool(forKey: DefaultsKey.serviceEnabled)
        gstChargeSwitch.isOn = defaults.bool(forKey: DefaultsKey.gstEnabled)
        payNowField.text = defaults.string(forKey: DefaultsKey.payNowNumber)
    }

    // whatever dynamically updates is here
    private func updateResults() {
        let bill = self.bill
        let formatter = CurrencyFormatter.shared

        subtotalLabel.text = "Subtotal: \(formatter.string(from: bill.billAmount))"

        serviceAmountLabel.text = "Service (\(bill.servicePercent)%): \(formatter.string(from: bill.serviceChargeAmount))"
        serviceAmountLabel.isHidden = !bill.serviceEnabled

        gstAmountLabel.text = "GST (\(bill.gstPercent)%): \(formatter.string(from: bill.gstAmount))"
        gstAmountLabel.isHidden = !bill.gstEnabled

        totalLabel.text = "Total: \(formatter.string(from: bill.displayTotal))"
        perPersonLabel.text = "Split between \(bill.partySize): \(formatter.string(from: bill.displayPerPerson))"

        shareButton.isEnabled = bill.billAmount > 0
        updateQRCode(for: bill)
    }

    private func updateQRCode(for bill: BillModel) {
        let number = payNowField.text ?? ""
        let image = bill.displayPerPerson > 0
            ? PayNowQR.image(mobileNumber: number, amount: bill.displayPerPerson)
            : nil

        qrImageView.image = image
        qrImageView.isHidden = image == nil
        qrCaptionLabel.isHidden = image == nil
    }

    private func refreshPeopleLabel() {
        peopleLabel.text = partySize == 1 ? "1 person" : "\(partySize) people"
    }

    private func refreshRoundingButton() {
        roundingButton.configuration?.title = "Rounding: \(roundingStrategy.title)"
        roundingButton.menu = UIMenu(children: RoundingStrategy.allCases.map { strategy in
            UIAction(title: strategy.title, state: strategy == roundingStrategy ? .on : .off) { [weak self] _ in
                self?.roundingStrategy = strategy
                self?.refreshRoundingButton()
                self?.updateResults()
            }
        })
    }

    private func resetBill() {
        billAmount = 0
        billField.text = ""
        partySize = 2
        peopleStepper.value = 2
        roundingStrategy = .none
        serviceChargeSwitch.setOn(false, animated: true)
        gstChargeSwitch.setOn(false, animated: true)
        UserDefaults.standard.set(false, forKey: DefaultsKey.serviceEnabled)
        UserDefaults.standard.set(false, forKey: DefaultsKey.gstEnabled)
        refreshPeopleLabel()
        refreshRoundingButton()
        view.endEditing(true)
        updateResults()
    }

    private func snapshotResultsCard() -> UIImage? {
        resultsContainerView.layoutIfNeeded()

        return UIGraphicsImageRenderer(bounds: resultsContainerView.bounds).image { context in
            resultsContainerView.drawHierarchy(in: resultsContainerView.bounds, afterScreenUpdates: true)
        }
    }

    private func shareResults() {
        view.endEditing(true)
        guard let image = snapshotResultsCard() else { return }

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = shareButton
        present(activityVC, animated: true)
    }

    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField === billField else { return true }

        guard let result = CurrencyFormatter.shared.formattedReplacement(
            currentText: textField.text ?? "",
            range: range,
            replacement: string
        ) else { return false }

        textField.text = result.formatted
        billAmount = result.decimal ?? 0
        updateResults()
        return false
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField === billField {
            billAmount = 0
            textField.text = ""
            updateResults()
            return false
        }
        return true
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private static func makeResultLabel(size: CGFloat = 20, color: UIColor = .black) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: size)
        label.textColor = color
        label.numberOfLines = 0
        return label
    }
}

#Preview {
    ViewController()
}
