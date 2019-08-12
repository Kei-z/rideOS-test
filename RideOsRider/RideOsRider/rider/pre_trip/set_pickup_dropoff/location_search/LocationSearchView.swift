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

class LocationSearchView: UIView {
    private static let searchMenuContainerViewBackgroundColor =
        RideOsRiderResourceLoader.instance.getColor("ai.rideos.rider.location-search.background-color")

    private let pickupTextField = LocationSearchTextField(leftImage: RiderImages.locationDot())
    private let dropoffTextField = LocationSearchTextField(leftImage: RiderImages.greyPin())
    private let doneButton = UIButton(type: .custom)
    private let searchResultsTableView = LocationSearchTableView()

    public var pickupTextFieldTextEvents: ControlProperty<String?> {
        return pickupTextField.rx.text
    }

    public var dropoffTextFieldTextEvents: ControlProperty<String?> {
        return dropoffTextField.rx.text
    }

    public var pickupTextFieldText: String? {
        get {
            return pickupTextField.text
        }
        set {
            pickupTextField.text = newValue
        }
    }

    public var dropoffTextFieldText: String? {
        get {
            return dropoffTextField.text
        }
        set {
            dropoffTextField.text = newValue
        }
    }

    private let focusBehaviorSubject = BehaviorSubject<LocationSearchFocusType>(value: .dropoff)
    public var focusObservable: Observable<LocationSearchFocusType> {
        return focusBehaviorSubject
    }

    public var doneButtonTapEvents: ControlEvent<Void> {
        return doneButton.rx.tap
    }

    public var isDoneButtonVisible: Bool {
        get {
            return !doneButton.isHidden
        }
        set {
            doneButton.isHidden = !newValue
        }
    }

    public var tableViewSelectionEvents: ControlEvent<LocationSearchOption> {
        return searchResultsTableView.rx.modelSelected(LocationSearchOption.self)
    }

    public var cancelButtonTapEvents: ControlEvent<Void> {
        return cancelButton.tapEvents
    }

    // Search Menu
    private let searchMenuContainerView = UIView(frame: .zero)
    private static let searchMenuContainerNormalViewHeight: CGFloat = 175.0

    private static let cancelButtonToPickupTextFieldVerticalSpacing: CGFloat = 12.0
    private static let textFieldVerticalSpacing: CGFloat = 8.0

    private let cancelButton = SquareImageButton(
        image: RiderImages.backSmall(),
        backgroundColor: .clear,
        enableShadows: false
    )

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white

        // Search Menu Container
        searchMenuContainerView.clipsToBounds = false
        searchMenuContainerView.backgroundColor = LocationSearchView.searchMenuContainerViewBackgroundColor

        addSubview(searchMenuContainerView)
        searchMenuContainerView.layer.borderColor = UIColor.red.cgColor
        searchMenuContainerView.translatesAutoresizingMaskIntoConstraints = false
        searchMenuContainerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        searchMenuContainerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        searchMenuContainerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        searchMenuContainerView.heightAnchor
            .constraint(equalToConstant: LocationSearchView.searchMenuContainerNormalViewHeight)
            .isActive = true

        // Cancel button
        searchMenuContainerView.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.leadingAnchor
            .constraint(equalTo: searchMenuContainerView.layoutMarginsGuide.leadingAnchor)
            .isActive = true
        cancelButton.topAnchor
            .constraint(equalTo: searchMenuContainerView.layoutMarginsGuide.topAnchor)
            .isActive = true

        // Done button
        searchMenuContainerView.addSubview(doneButton)
        doneButton.setTitle(
            RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.location-search.done-button-title"),
            for: .normal
        )
        doneButton.isHidden = true
        doneButton.contentHorizontalAlignment = .trailing
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.trailingAnchor
            .constraint(equalTo: searchMenuContainerView.layoutMarginsGuide.trailingAnchor)
            .isActive = true
        doneButton.topAnchor.constraint(equalTo: searchMenuContainerView.layoutMarginsGuide.topAnchor).isActive = true

        // Pickup Text Field
        searchMenuContainerView.addSubview(pickupTextField)
        initializeTextFieldConstraints(textField: pickupTextField)
        pickupTextField.topAnchor.constraint(
            equalTo: cancelButton.bottomAnchor,
            constant: LocationSearchView.cancelButtonToPickupTextFieldVerticalSpacing
        ).isActive = true

        // Dropoff Text Field
        searchMenuContainerView.addSubview(dropoffTextField)
        initializeTextFieldConstraints(textField: dropoffTextField)
        dropoffTextField.topAnchor
            .constraint(equalTo: pickupTextField.bottomAnchor, constant: LocationSearchView.textFieldVerticalSpacing)
            .isActive = true

        // Search Results
        addSubview(searchResultsTableView)
        searchResultsTableView.translatesAutoresizingMaskIntoConstraints = false
        searchResultsTableView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        searchResultsTableView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        searchResultsTableView.topAnchor.constraint(equalTo: searchMenuContainerView.bottomAnchor).isActive = true
        searchResultsTableView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    public func makeDropoffTextFieldFirstResponder() {
        dropoffTextField.becomeFirstResponder()
    }

    public func textFieldsResignFirstResponder() {
        pickupTextField.resignFirstResponder()
        dropoffTextField.resignFirstResponder()
    }

    private func initializeTextFieldConstraints(textField: UITextField) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.leadingAnchor
            .constraint(equalTo: searchMenuContainerView.layoutMarginsGuide.leadingAnchor)
            .isActive = true
        textField.widthAnchor
            .constraint(equalTo: searchMenuContainerView.layoutMarginsGuide.widthAnchor)
            .isActive = true
        textField.delegate = self
    }

    public func bindToSearchResultsTableView(_ locationSearchOptions: Observable<[LocationSearchOption]>)
        -> Disposable {
        return locationSearchOptions
            .bind(to: searchResultsTableView.rx.items) { [searchResultsTableView] _, _, locationSearchOption in
                searchResultsTableView.dequeueReusableCell(forLocationSearchOption: locationSearchOption)
            }
    }
}

// MARK: UITextFieldDelegate

extension LocationSearchView: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == pickupTextField {
            focusBehaviorSubject.onNext(.pickup)
        } else if textField == dropoffTextField {
            focusBehaviorSubject.onNext(.dropoff)
        }
    }
}
