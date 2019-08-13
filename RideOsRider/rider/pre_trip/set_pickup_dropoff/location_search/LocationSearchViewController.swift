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

import Foundation
import RideOsCommon
import RxCocoa
import RxSwift

public class LocationSearchViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let locationSearchView = LocationSearchView()

    private let locationSearchViewModel: LocationSearchViewModel
    private let schedulerProvider: SchedulerProvider

    public required init?(coder _: NSCoder) {
        fatalError("LocationSearchViewController does not support NSCoder")
    }

    public init(_ locationSearchViewModel: LocationSearchViewModel,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.locationSearchViewModel = locationSearchViewModel
        self.schedulerProvider = schedulerProvider
        super.init(nibName: nil, bundle: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(locationSearchView)
        view.activateMaxSizeConstraintsOnSubview(locationSearchView)

        // Update the view model when the pickup/dropoff text boxes change
        locationSearchView.pickupTextFieldTextEvents
            .orEmpty
            .asSignal(onErrorJustReturn: "")
            .emit(onNext: { [locationSearchViewModel] value in
                locationSearchViewModel.setPickupText(value)
            })
            .disposed(by: disposeBag)
        locationSearchView.dropoffTextFieldTextEvents
            .orEmpty
            .asSignal(onErrorJustReturn: "")
            .emit(onNext: { [locationSearchViewModel] value in
                locationSearchViewModel.setDropoffText(value)
            })
            .disposed(by: disposeBag)

        // When the user selects a pickup or dropoff, update the relevant text box with the displayName of the selection
        locationSearchViewModel.getSelectedPickup()
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [locationSearchView] selectedPickup in
                locationSearchView.pickupTextFieldText = selectedPickup
            })
            .disposed(by: disposeBag)
        locationSearchViewModel.getSelectedDropOff()
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [locationSearchView] selectedDropoff in
                locationSearchView.dropoffTextFieldText = selectedDropoff
            })
            .disposed(by: disposeBag)

        // Update the search results table as the search/autocomplete results change
        locationSearchView
            .bindToSearchResultsTableView(
                locationSearchViewModel
                    .getLocationOptions()
                    .observeOn(schedulerProvider.mainThread())
            )
            .disposed(by: disposeBag)

        // Update the view model when the user selects one of the search results in the table
        locationSearchView.tableViewSelectionEvents
            .asSignal()
            .emit(onNext: { [locationSearchViewModel] selection in
                locationSearchViewModel.makeSelection(selection)
            })
            .disposed(by: disposeBag)

        // Enable the done button when the view model says so
        locationSearchViewModel.isDoneActionEnabled()
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [locationSearchView] isDoneEnabled in
                locationSearchView.isDoneButtonVisible = isDoneEnabled
            })
            .disposed(by: disposeBag)

        // When the user taps the done button, notify the view model
        locationSearchView.doneButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [locationSearchViewModel] _ in locationSearchViewModel.done() })
            .disposed(by: disposeBag)

        locationSearchView.cancelButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [locationSearchViewModel] _ in locationSearchViewModel.cancel() })
            .disposed(by: disposeBag)

        locationSearchView.focusObservable
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: locationSearchViewModel.setFocus)
            .disposed(by: disposeBag)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Activate dropoff text field
        locationSearchView.makeDropoffTextFieldFirstResponder()
    }

    public override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            locationSearchView.textFieldsResignFirstResponder()
        }
    }
}
