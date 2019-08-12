import CoreLocation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxSwift
import RxTest
import XCTest

class DefaultPreTripViewModelTest: ReactiveTestCase {
    private static let tripId = "trip_id"

    private static let pickupLocation = PreTripLocation(
        desiredAndAssignedLocation: DesiredAndAssignedLocation(
            desiredLocation: NamedTripLocation(
                tripLocation: TripLocation(location: CLLocationCoordinate2D(latitude: 0, longitude: 0)),
                displayName: "pickup"
            )
        ),
        wasSetOnMap: false
    )

    private static let confirmedPickupLocation = DesiredAndAssignedLocation(
        desiredLocation: NamedTripLocation(
            tripLocation: TripLocation(location: CLLocationCoordinate2D(latitude: 2, longitude: 2)),
            displayName: "confirmed pickup"
        )
    )

    private static let dropoffLocation = PreTripLocation(
        desiredAndAssignedLocation: DesiredAndAssignedLocation(
            desiredLocation: NamedTripLocation(
                tripLocation: TripLocation(location: CLLocationCoordinate2D(latitude: 1, longitude: 1)),
                displayName: "dropoff"
            )
        ),
        wasSetOnMap: false
    )

    private static let confirmedDropoffLocation = DesiredAndAssignedLocation(
        desiredLocation: NamedTripLocation(
            tripLocation: TripLocation(location: CLLocationCoordinate2D(latitude: 3, longitude: 3)),
            displayName: "confirmed dropoff"
        )
    )

    var viewModelUnderTest: DefaultPreTripViewModel!
    var stateRecorder: TestableObserver<PreTripState>!
    var listener: RecordingPreTripListener!

    func setUp(enableSeatCountSelection: Bool,
               createTripObservable: Observable<String> = Observable.just(DefaultPreTripViewModelTest.tripId)) {
        super.setUp()

        ResolvedFleet.instance.set(resolvedFleet: FleetInfo.defaultFleetInfo)

        listener = RecordingPreTripListener()

        viewModelUnderTest = DefaultPreTripViewModel(
            userStorageReader: UserDefaultsUserStorageReader(
                userDefaults: TemporaryUserDefaults(stringValues: [CommonUserStorageKeys.userId: "user id"])
            ),
            tripInteractor: FixedTripInteractor(
                createTripObservable: createTripObservable,
                cancelTripCompletable: Completable.never()
            ),
            listener: listener,
            enableSeatCountSelection: enableSeatCountSelection,
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            passengerName: Observable.just(""),
            logger: ConsoleLogger()
        )

        stateRecorder = scheduler.createObserver(PreTripState.self)
        viewModelUnderTest.getPreTripState()
            .asDriver(onErrorJustReturn: .selectingPickupDropoff)
            .drive(stateRecorder)
            .disposed(by: disposeBag)

        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }

    func testInitialStateIsSelectingPickupDropoff() {
        setUp(enableSeatCountSelection: false)
        XCTAssertRecordedElements(stateRecorder.events, [.selectingPickupDropoff])
    }

    func testSelectingPickupDropoffTransitionsToConfirmingDropoff() {
        setUp(enableSeatCountSelection: false)
        viewModelUnderTest.set(pickup: DefaultPreTripViewModelTest.pickupLocation,
                               dropoff: DefaultPreTripViewModelTest.dropoffLocation)
        scheduler.start()

        XCTAssertRecordedElements(
            stateRecorder.events,
            [
                .selectingPickupDropoff,
                .confirmingDropoff(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                   unconfirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation),
            ]
        )
        XCTAssertEqual(listener.tripsCreated, [])
        XCTAssertEqual(listener.methodCalls, [])
    }

    func testConfirmingDropoffTransitionsToConfirmingPickup() {
        setUp(enableSeatCountSelection: false)
        viewModelUnderTest.set(pickup: DefaultPreTripViewModelTest.pickupLocation,
                               dropoff: DefaultPreTripViewModelTest.dropoffLocation)
        viewModelUnderTest.confirmLocation(DefaultPreTripViewModelTest.confirmedDropoffLocation)
        scheduler.start()

        XCTAssertRecordedElements(
            stateRecorder.events,
            [
                .selectingPickupDropoff,
                .confirmingDropoff(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                   unconfirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation),
                .confirmingPickup(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                  confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation),
            ]
        )
        XCTAssertEqual(listener.tripsCreated, [])
        XCTAssertEqual(listener.methodCalls, [])
    }

    func testConfirmingPickupTransitionsToConfirmingTrip() {
        setUp(enableSeatCountSelection: false)
        viewModelUnderTest.set(pickup: DefaultPreTripViewModelTest.pickupLocation,
                               dropoff: DefaultPreTripViewModelTest.dropoffLocation)
        // Confirm dropoff
        viewModelUnderTest.confirmLocation(DefaultPreTripViewModelTest.confirmedDropoffLocation)
        // Confirm pickup
        viewModelUnderTest.confirmLocation(DefaultPreTripViewModelTest.confirmedPickupLocation)
        scheduler.start()

        XCTAssertRecordedElements(
            stateRecorder.events,
            [
                .selectingPickupDropoff,
                .confirmingDropoff(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                   unconfirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation),
                .confirmingPickup(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                  confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation),
                .confirmingTrip(confirmedPickupLocation: DefaultPreTripViewModelTest.confirmedPickupLocation,
                                confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation),
            ]
        )
        XCTAssertEqual(listener.tripsCreated, [])
        XCTAssertEqual(listener.methodCalls, [])
    }

    func testConfirmingTripTransitionsToConfirmedAndCallsListenerOnTripCreated() {
        setUp(enableSeatCountSelection: false)
        scheduler.scheduleAt(0) {
            self.viewModelUnderTest.set(pickup: DefaultPreTripViewModelTest.pickupLocation,
                                        dropoff: DefaultPreTripViewModelTest.dropoffLocation)
            self.viewModelUnderTest.confirmLocation(DefaultPreTripViewModelTest.confirmedDropoffLocation)
            self.viewModelUnderTest.confirmLocation(DefaultPreTripViewModelTest.confirmedPickupLocation)
            self.viewModelUnderTest.confirmTrip(selectedVehicle: .automatic)
        }

        scheduler.start()

        XCTAssertEqual(stateRecorder.events, [
            next(0, .selectingPickupDropoff),
            next(1, .confirmingDropoff(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                       unconfirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation)),
            next(2, .confirmingPickup(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                      confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation)),
            next(3, .confirmingTrip(confirmedPickupLocation: DefaultPreTripViewModelTest.confirmedPickupLocation,
                                    confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation)),
            next(4, .confirmed(confirmedPickupLocation: DefaultPreTripViewModelTest.confirmedPickupLocation,
                               confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation,
                               numPassengers: 1,
                               selectedVehicle: .automatic))
        ])

        XCTAssertEqual(listener.tripsCreated, [DefaultPreTripViewModelTest.tripId])
        XCTAssertEqual(listener.methodCalls, ["onTripCreated(tripId:)"])
    }

    func testTripCreationFailureReturnsToConfirmingTripState() {
        setUp(enableSeatCountSelection: false,
              createTripObservable: Observable.error(TripInteractorError.invalidResponse))

        stateRecorder = scheduler.createObserver(PreTripState.self)
        viewModelUnderTest.getPreTripState()
            .asDriver(onErrorJustReturn: .selectingPickupDropoff)
            .drive(stateRecorder)
            .disposed(by: disposeBag)

        scheduler.scheduleAt(0) {
            self.viewModelUnderTest.set(pickup: DefaultPreTripViewModelTest.pickupLocation,
                                        dropoff: DefaultPreTripViewModelTest.dropoffLocation)
            self.viewModelUnderTest.confirmLocation(DefaultPreTripViewModelTest.confirmedDropoffLocation)
            self.viewModelUnderTest.confirmLocation(DefaultPreTripViewModelTest.confirmedPickupLocation)
            self.viewModelUnderTest.confirmTrip(selectedVehicle: .automatic)
        }

        scheduler.start()

        XCTAssertEqual(stateRecorder.events, [
            next(0, .selectingPickupDropoff),
            next(1, .confirmingDropoff(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                       unconfirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation)),
            next(2, .confirmingPickup(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                      confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation)),
            next(3, .confirmingTrip(confirmedPickupLocation: DefaultPreTripViewModelTest.confirmedPickupLocation,
                                    confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation)),
            next(4, .confirmed(confirmedPickupLocation: DefaultPreTripViewModelTest.confirmedPickupLocation,
                               confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation,
                               numPassengers: 1,
                               selectedVehicle: .automatic)),
            next(6, .confirmingTrip(confirmedPickupLocation: DefaultPreTripViewModelTest.confirmedPickupLocation,
                                    confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation))
        ])

        XCTAssertEqual(listener.tripsCreated, [])
        XCTAssertEqual(listener.methodCalls, [])
    }

    func testCancelInvokesCancelOnListener() {
        setUp(enableSeatCountSelection: false)
        viewModelUnderTest.cancelSetPickupDropoff()
        XCTAssertEqual(listener.methodCalls, ["cancelPreTrip()"])
    }

    func testCancelConfirmLocationWhileConfirmingDropoffTransitionsToSelectingPickupDropoff() {
        setUp(enableSeatCountSelection: false)
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.set(pickup: DefaultPreTripViewModelTest.pickupLocation,
                                        dropoff: DefaultPreTripViewModelTest.dropoffLocation)
        })
        scheduler.scheduleAt(2, action: {
            self.viewModelUnderTest.cancelConfirmLocation()
        })
        scheduler.start()

        XCTAssertEqual(
            stateRecorder.events,
            [
                next(0, .selectingPickupDropoff),
                next(2, .confirmingDropoff(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                           unconfirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation)),
                next(3, .selectingPickupDropoff)
            ]
        )
        XCTAssertEqual(listener.tripsCreated, [])
        XCTAssertEqual(listener.methodCalls, [])
    }

    func testCancelConfirmLocationWhileConfirmingPickupTransitionsToSelectingPickupDropoff() {
        setUp(enableSeatCountSelection: false)
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.set(pickup: DefaultPreTripViewModelTest.pickupLocation,
                                        dropoff: DefaultPreTripViewModelTest.dropoffLocation)
        })
        scheduler.scheduleAt(2, action: {
            self.viewModelUnderTest.confirmLocation(DefaultPreTripViewModelTest.confirmedDropoffLocation)
        })
        scheduler.scheduleAt(3, action: {
            self.viewModelUnderTest.cancelConfirmLocation()
        })
        scheduler.start()

        XCTAssertEqual(
            stateRecorder.events,
            [
                next(0, .selectingPickupDropoff),
                next(2, .confirmingDropoff(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                           unconfirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation)),
                next(3, .confirmingPickup(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                          confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation)),
                next(4, .selectingPickupDropoff)
            ]
        )
        XCTAssertEqual(listener.tripsCreated, [])
        XCTAssertEqual(listener.methodCalls, [])
    }

    func testCancelConfirmTripTransitionsToSelectingPickupDropoff() {
        setUp(enableSeatCountSelection: false)
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.set(pickup: DefaultPreTripViewModelTest.pickupLocation,
                                        dropoff: DefaultPreTripViewModelTest.dropoffLocation)
        })
        scheduler.scheduleAt(2, action: {
            self.viewModelUnderTest.confirmLocation(DefaultPreTripViewModelTest.confirmedDropoffLocation)
        })
        scheduler.scheduleAt(3, action: {
            self.viewModelUnderTest.confirmLocation(DefaultPreTripViewModelTest.confirmedPickupLocation)
        })
        scheduler.scheduleAt(4, action: {
            self.viewModelUnderTest.cancelConfirmTrip()
        })
        scheduler.start()

        XCTAssertEqual(
            stateRecorder.events,
            [
                next(0, .selectingPickupDropoff),
                next(2, .confirmingDropoff(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                           unconfirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation)),
                next(3, .confirmingPickup(unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                                          confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation)),
                next(4, .confirmingTrip(confirmedPickupLocation: DefaultPreTripViewModelTest.confirmedPickupLocation,
                                        confirmedDropoffLocation: DefaultPreTripViewModelTest.confirmedDropoffLocation)),
                next(5, .selectingPickupDropoff)
            ]
        )
        XCTAssertEqual(listener.tripsCreated, [])
        XCTAssertEqual(listener.methodCalls, [])
    }

    func testCancelTripRequestCallsCancelPreTripOnListener() {
        setUp(enableSeatCountSelection: false)
        viewModelUnderTest.cancelTripRequest()
        XCTAssertEqual(listener.methodCalls, ["cancelPreTrip()"])
    }

    func testPickupAndDropoffBothSetOnMapSkipsPickupAndDropoffConfirmation() {
        setUp(enableSeatCountSelection: false)
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.set(
                pickup: PreTripLocation(
                    desiredAndAssignedLocation: DefaultPreTripViewModelTest.pickupLocation.desiredAndAssignedLocation,
                    wasSetOnMap: true
                ),
                dropoff: PreTripLocation(
                    desiredAndAssignedLocation: DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation,
                    wasSetOnMap: true
                )
            )
        })

        scheduler.start()

        XCTAssertEqual(
            stateRecorder.events,
            [
                next(0, .selectingPickupDropoff),
                next(
                    2,
                    .confirmingTrip(
                        confirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation.desiredAndAssignedLocation,
                        confirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation
                    )
                ),
            ]
        )
    }

    func testDropoffSetOnMapSkipsDropoffConfirmation() {
        setUp(enableSeatCountSelection: false)
        let dropoffLocation = PreTripLocation(
            desiredAndAssignedLocation: DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation,
            wasSetOnMap: true
        )
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.set(pickup: DefaultPreTripViewModelTest.pickupLocation, dropoff: dropoffLocation)
        })

        scheduler.start()

        XCTAssertEqual(
            stateRecorder.events,
            [
                next(0, .selectingPickupDropoff),
                next(
                    2,
                    .confirmingPickup(
                        unconfirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation,
                        confirmedDropoffLocation: dropoffLocation.desiredAndAssignedLocation
                    )
                ),
            ]
        )
    }

    func testPickupSetOnMapSkipsPickupConfirmation() {
        setUp(enableSeatCountSelection: false)
        let pickupLocation = PreTripLocation(
            desiredAndAssignedLocation: DefaultPreTripViewModelTest.pickupLocation.desiredAndAssignedLocation,
            wasSetOnMap: true
        )
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.set(pickup: pickupLocation, dropoff: DefaultPreTripViewModelTest.dropoffLocation)
        })
        scheduler.scheduleAt(2, action: {
            self.viewModelUnderTest.confirmLocation(DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation)
        })

        scheduler.start()

        XCTAssertEqual(
            stateRecorder.events,
            [
                next(0, .selectingPickupDropoff),
                next(
                    2,
                    .confirmingDropoff(
                        unconfirmedPickupLocation: pickupLocation,
                        unconfirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation
                    )
                ),
                next(
                    3,
                    .confirmingTrip(
                        confirmedPickupLocation: pickupLocation.desiredAndAssignedLocation,
                        confirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation
                    )
                ),
            ]
        )
    }

    func testConfirmingTripWithSeatCountSelectionEnabledTransitionsToConfirmingSeatsState() {
        setUp(enableSeatCountSelection: true)
        scheduler.scheduleAt(1) {
            self.viewModelUnderTest.set(
                pickup: PreTripLocation(
                    desiredAndAssignedLocation: DefaultPreTripViewModelTest.pickupLocation.desiredAndAssignedLocation,
                    wasSetOnMap: true
                ),
                dropoff: PreTripLocation(
                    desiredAndAssignedLocation: DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation,
                    wasSetOnMap: true
                )
            )
            self.viewModelUnderTest.confirmTrip(selectedVehicle: .automatic)
        }
        scheduler.start()

        XCTAssertEqual(
            stateRecorder.events,
            [
                next(0, .selectingPickupDropoff),
                next(
                    2,
                    .confirmingTrip(
                        confirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation.desiredAndAssignedLocation,
                        confirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation
                    )
                ),
                next(
                    3,
                    .confirmingSeats(
                        confirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation.desiredAndAssignedLocation,
                        confirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation,
                        selectedVehicle: .automatic
                    )
                )
            ]
        )
    }

    func testConfirmingSeatsTransitionsToConfirmedState() {
        let seatCount: UInt32 = 3
        setUp(enableSeatCountSelection: true)
        scheduler.scheduleAt(1) {
            self.viewModelUnderTest.set(
                pickup: PreTripLocation(
                    desiredAndAssignedLocation: DefaultPreTripViewModelTest.pickupLocation.desiredAndAssignedLocation,
                    wasSetOnMap: true
                ),
                dropoff: PreTripLocation(
                    desiredAndAssignedLocation: DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation,
                    wasSetOnMap: true
                )
            )
            self.viewModelUnderTest.confirmTrip(selectedVehicle: .automatic)
            self.viewModelUnderTest.confirm(seatCount: seatCount)
        }

        scheduler.start()

        XCTAssertEqual(
            stateRecorder.events,
            [
                next(0, .selectingPickupDropoff),
                next(
                    2,
                    .confirmingTrip(
                        confirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation.desiredAndAssignedLocation,
                        confirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation
                    )
                ),
                next(
                    3,
                    .confirmingSeats(
                        confirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation.desiredAndAssignedLocation,
                        confirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation,
                        selectedVehicle: .automatic
                    )
                ),
                next(
                    4,
                    .confirmed(
                        confirmedPickupLocation: DefaultPreTripViewModelTest.pickupLocation.desiredAndAssignedLocation,
                        confirmedDropoffLocation: DefaultPreTripViewModelTest.dropoffLocation.desiredAndAssignedLocation,
                        numPassengers: seatCount,
                        selectedVehicle: .automatic
                    )
                )
            ]
        )
    }
}

class RecordingPreTripListener: MethodCallRecorder, PreTripListener {
    var tripsCreated: [String] = []

    func onTripCreated(tripId: String) {
        tripsCreated.append(tripId)
        recordMethodCall(#function)
    }

    func cancelPreTrip() {
        recordMethodCall(#function)
    }
}
