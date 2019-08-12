// Copyright 2019 rideOS, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import RideOsCommon
import RxCocoa
import RxSwift
import UIKit

public class VehicleRegistrationView: UIView {
    private let vehicleRegistrationContainerView = VehicleRegistrationView.vehicleRegistrationContainerView()

    private let cancelButton = VehicleRegistrationView.cancelButton()

    private static let buttonColorEnabled =
        RideOsDriverResourceLoader.instance.getColor("ai.rideos.driver.submit-button.color.enabled")
    private static let buttonColorDisabled =
        RideOsDriverResourceLoader.instance.getColor("ai.rideos.driver.submit-button.color.disabled")
    private let submitButton = VehicleRegistrationView.submitButton()

    private let accountHeaderLabel = VehicleRegistrationView.accountHeaderLabel()
    private let descriptionLabel = VehicleRegistrationView.descriptionLabel()
    private let vehicleHeaderLabel = VehicleRegistrationView.vehicleHeaderLabel()

    private let firstNameField = VehicleRegistrationView.firstNameField()
    private let phoneNumberField = VehicleRegistrationView.phoneNumberField()
    private let licensePlateField = VehicleRegistrationView.licensePlateField()
    private let riderCapacityField = VehicleRegistrationView.riderCapacityField()

    public var cancelButtonTapEvents: ControlEvent<Void> {
        return cancelButton.tapEvents
    }

    public var submitButtonTapEvents: ControlEvent<Void> {
        return submitButton.rx.tap
    }

    public var isSubmitButtonEnabled: Bool {
        get {
            return submitButton.isEnabled
        }
        set {
            submitButton.isEnabled = newValue
            if newValue {
                submitButton.backgroundColor = VehicleRegistrationView.buttonColorEnabled
            } else {
                submitButton.backgroundColor = VehicleRegistrationView.buttonColorDisabled
            }
        }
    }

    public var firstNameFieldTextEvents: ControlProperty<String?> {
        return firstNameField.rx.text
    }

    public var phoneNumberFieldTextEvents: ControlProperty<String?> {
        return phoneNumberField.rx.text
    }

    public var licensePlateFieldTextEvents: ControlProperty<String?> {
        return licensePlateField.rx.text
    }

    public var riderCapacityFieldTextEvents: ControlProperty<String?> {
        return riderCapacityField.rx.text
    }

    public var firstNameFieldText: String? {
        get {
            return firstNameField.text
        }
        set {
            firstNameField.text = newValue
        }
    }

    public var phoneNumberFieldText: String? {
        get {
            return phoneNumberField.text
        }
        set {
            phoneNumberField.text = newValue
        }
    }

    public var licensePlateFieldText: String? {
        get {
            return licensePlateField.text
        }
        set {
            licensePlateField.text = newValue
        }
    }

    public var riderCapacityFieldText: String? {
        get {
            return riderCapacityField.text
        }
        set {
            riderCapacityField.text = newValue
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(vehicleRegistrationContainerView)
        activateMaxSizeConstraintsOnSubview(vehicleRegistrationContainerView)

        vehicleRegistrationContainerView.addArrangedSubview(cancelButton)

        vehicleRegistrationContainerView.addArrangedSubview(accountHeaderLabel)
        vehicleRegistrationContainerView.setCustomSpacing(14, after: accountHeaderLabel)

        vehicleRegistrationContainerView.addArrangedSubview(descriptionLabel)

        vehicleRegistrationContainerView.addArrangedSubview(firstNameField)
        initializeTextFieldConstraints(textField: firstNameField)
        vehicleRegistrationContainerView.setCustomSpacing(10, after: firstNameField)

        vehicleRegistrationContainerView.addArrangedSubview(phoneNumberField)
        initializeTextFieldConstraints(textField: phoneNumberField)

        vehicleRegistrationContainerView.addArrangedSubview(vehicleHeaderLabel)

        vehicleRegistrationContainerView.addArrangedSubview(licensePlateField)
        initializeTextFieldConstraints(textField: licensePlateField)
        vehicleRegistrationContainerView.setCustomSpacing(10, after: licensePlateField)

        vehicleRegistrationContainerView.addArrangedSubview(riderCapacityField)
        initializeTextFieldConstraints(textField: riderCapacityField)

        vehicleRegistrationContainerView.addArrangedSubview(UIView(frame: .zero))

        vehicleRegistrationContainerView.addArrangedSubview(submitButton)
        submitButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        submitButton.widthAnchor.constraint(equalTo: vehicleRegistrationContainerView.layoutMarginsGuide.widthAnchor)
            .isActive = true
        submitButton.isEnabled = false
    }

    private func initializeTextFieldConstraints(textField: UITextField) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        textField.widthAnchor.constraint(equalTo: vehicleRegistrationContainerView.layoutMarginsGuide.widthAnchor)
            .isActive = true
    }
}

extension VehicleRegistrationView {
    private static func vehicleRegistrationContainerView() -> UIStackView {
        let vehicleRegistrationContainerView = UIStackView()
        vehicleRegistrationContainerView.axis = .vertical
        vehicleRegistrationContainerView.alignment = .leading
        vehicleRegistrationContainerView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        vehicleRegistrationContainerView.isLayoutMarginsRelativeArrangement = true
        vehicleRegistrationContainerView.spacing = 18
        return vehicleRegistrationContainerView
    }

    private static func submitButton() -> UIButton {
        let submitButton = UIButton(type: .custom)
        submitButton.setTitle(RideOsDriverResourceLoader
            .instance.getString("ai.rideos.driver.settings.submit.button.title"), for: .normal)
        submitButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        submitButton.layer.cornerRadius = 4.0
        submitButton.backgroundColor = .black
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        return submitButton
    }

    private static func cancelButton() -> SquareImageButton {
        let cancelButton = SquareImageButton(image: DriverImages.close(),
                                             backgroundColor: .clear,
                                             enableShadows: false)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        return cancelButton
    }

    private static func accountHeaderLabel() -> UILabel {
        let accountHeaderLabel = UILabel()
        accountHeaderLabel.font = UIFont.systemFont(ofSize: 16)
        accountHeaderLabel.text = RideOsDriverResourceLoader
            .instance.getString("ai.rideos.driver.settings.account")
        accountHeaderLabel.textAlignment = .left
        accountHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        return accountHeaderLabel
    }

    private static func descriptionLabel() -> UILabel {
        let descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.text = RideOsDriverResourceLoader
            .instance.getString("ai.rideos.driver.settings.account.subheader.title")
        descriptionLabel.textAlignment = .left
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        return descriptionLabel
    }

    private static func vehicleHeaderLabel() -> UILabel {
        let vehicleHeaderLabel = UILabel()
        vehicleHeaderLabel.font = UIFont.systemFont(ofSize: 16)
        vehicleHeaderLabel.text = RideOsDriverResourceLoader
            .instance.getString("ai.rideos.driver.settings.vehicle")
        vehicleHeaderLabel.textAlignment = .left
        vehicleHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        return vehicleHeaderLabel
    }

    private static func firstNameField() -> UITextField {
        return registrationTextField(fieldName: RideOsDriverResourceLoader
            .instance.getString("ai.rideos.driver.settings.account.name"))
    }

    private static func phoneNumberField() -> UITextField {
        let phoneNumberField = registrationTextField(fieldName: RideOsDriverResourceLoader
            .instance.getString("ai.rideos.driver.settings.account.phone-number"))
        phoneNumberField.keyboardType = .phonePad
        return phoneNumberField
    }

    private static func licensePlateField() -> UITextField {
        let licensePlateField = registrationTextField(fieldName: RideOsDriverResourceLoader
            .instance.getString("ai.rideos.driver.settings.vehicle.license-plate"))
        licensePlateField.autocapitalizationType = .allCharacters
        return licensePlateField
    }

    private static func riderCapacityField() -> UITextField {
        let riderCapacityField = registrationTextField(fieldName: RideOsDriverResourceLoader
            .instance.getString("ai.rideos.driver.settings.vehicle.rider-capacity"))
        riderCapacityField.keyboardType = .numberPad
        return riderCapacityField
    }

    private static func registrationTextField(fieldName: String) -> UITextField {
        let textField = UITextField()
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.clearButtonMode = .whileEditing
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.placeholder = fieldName
        textField.borderStyle = .line

        return textField
    }
}
