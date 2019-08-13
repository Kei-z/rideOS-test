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
import RxOptional
import RxSwift

public class DefaultVehicleRegistrationViewModel: VehicleRegistrationViewModel {
    private let disposeBag = DisposeBag()

    private let vehicleRegistrationInfoRelay =
        BehaviorRelay(value: VehicleRegistration(name: "", phoneNumber: "",
                                                 licensePlate: "", riderCapacity: 0))
    private let registrationSubject = BehaviorSubject(value: false)

    private let userStorageReader: UserStorageReader
    private let userStorageWriter: UserStorageWriter
    private let driverVehicleInteractor: DriverVehicleInteractor
    private let schedulerProvider: SchedulerProvider
    private weak var registerVehicleListener: RegisterVehicleListener?

    public init(registerVehicleListener: RegisterVehicleListener,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                driverVehicleInteractor: DriverVehicleInteractor = DefaultDriverVehicleInteractor(),
                resolvedFleet: ResolvedFleet = ResolvedFleet.instance,
                userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                userStorageWriter: UserStorageWriter = UserDefaultsUserStorageWriter()) {
        self.registerVehicleListener = registerVehicleListener
        self.schedulerProvider = schedulerProvider
        self.driverVehicleInteractor = driverVehicleInteractor
        self.userStorageReader = userStorageReader
        self.userStorageWriter = userStorageWriter

        registrationSubject
            .observeOn(schedulerProvider.mainThread())
            .distinctUntilChanged()
            .filter { $0 }
            .withLatestFrom(vehicleRegistrationInfoRelay)
            .withLatestFrom(resolvedFleet.resolvedFleet) { ($0, $1) }
            .flatMapLatest { [unowned self] registrationInfo, fleetInfo in
                !DefaultVehicleRegistrationViewModel.isVehicleRegistrationInfoValid(vehicleInfo: registrationInfo) ?
                    Single.error(InvalidVehicleRegistrationInfoError.invalidInfo("Invalid registration info")) :
                    driverVehicleInteractor
                    .createVehicle(vehicleId: userStorageReader.userId,
                                   fleetId: fleetInfo.fleetId,
                                   vehicleInfo: registrationInfo)
                    .andThen(self.writeVehicleInfoToStorage(vehicleInfo: registrationInfo))
                    .andThen(Single.just(registerVehicleListener.finishVehicleRegistration()))
            }
            .subscribe(onCompleted: { [registrationSubject] in
                registrationSubject.onNext(false)
            })
            .disposed(by: disposeBag)
    }

    public func setFirstNameText(_ text: String) {
        let oldVehicleInfo = vehicleRegistrationInfoRelay.value
        let newVehicleInfo = VehicleRegistration(name: text,
                                                 phoneNumber: oldVehicleInfo.phoneNumber,
                                                 licensePlate: oldVehicleInfo.licensePlate,
                                                 riderCapacity: oldVehicleInfo.riderCapacity)
        vehicleRegistrationInfoRelay.accept(newVehicleInfo)
    }

    public func setPhoneNumberText(_ text: String) {
        let oldVehicleInfo = vehicleRegistrationInfoRelay.value
        let newVehicleInfo = VehicleRegistration(name: oldVehicleInfo.name,
                                                 phoneNumber: text,
                                                 licensePlate: oldVehicleInfo.licensePlate,
                                                 riderCapacity: oldVehicleInfo.riderCapacity)
        vehicleRegistrationInfoRelay.accept(newVehicleInfo)
    }

    public func setLicensePlateText(_ text: String) {
        let oldVehicleInfo = vehicleRegistrationInfoRelay.value
        let newVehicleInfo = VehicleRegistration(name: oldVehicleInfo.name,
                                                 phoneNumber: oldVehicleInfo.phoneNumber,
                                                 licensePlate: text,
                                                 riderCapacity: oldVehicleInfo.riderCapacity)
        vehicleRegistrationInfoRelay.accept(newVehicleInfo)
    }

    public func setRiderCapacityText(_ text: String) {
        let oldVehicleInfo = vehicleRegistrationInfoRelay.value
        let newVehicleInfo = VehicleRegistration(name: oldVehicleInfo.name,
                                                 phoneNumber: oldVehicleInfo.phoneNumber,
                                                 licensePlate: oldVehicleInfo.licensePlate,
                                                 riderCapacity: Int32(text) ?? 0)
        vehicleRegistrationInfoRelay.accept(newVehicleInfo)
    }

    public func submit() {
        registrationSubject.onNext(true)
    }

    public func cancel() {
        registerVehicleListener?.cancelVehicleRegistration()
    }

    public func isSubmitActionEnabled() -> Observable<Bool> {
        return vehicleRegistrationInfoRelay.asObservable()
            .map { info in DefaultVehicleRegistrationViewModel.isVehicleRegistrationInfoValid(vehicleInfo: info) }
    }

    private func writeVehicleInfoToStorage(vehicleInfo: VehicleRegistration) -> Completable {
        userStorageWriter.set(key: DriverSettingsKeys.vehicleInfo, value: vehicleInfo)
        return Completable.empty()
    }

    private static func isVehicleRegistrationInfoValid(vehicleInfo: VehicleRegistration) -> Bool {
        return vehicleInfo.name.isNotEmpty && vehicleInfo.phoneNumber.isNotEmpty
            && vehicleInfo.licensePlate.isNotEmpty && vehicleInfo.riderCapacity > 0
    }
}
