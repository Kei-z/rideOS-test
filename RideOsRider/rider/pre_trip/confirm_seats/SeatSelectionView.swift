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
import RxSwift

public class SeatSelectionView: UIView {
    private static let seatCount: [UInt32] = [1, 2, 3, 4]
    private static let selectedImage =
        RideOsRiderResourceLoader.instance.getImage("ai.rideos.rider.seat-selection.circle")
    private static let deselectedImage =
        RideOsRiderResourceLoader.instance.getImage("ai.rideos.rider.seat-selection.deselected-image")
    private static let selectedTitleColor =
        RideOsRiderResourceLoader.instance.getColor("ai.rideos.rider.seat-selection.buttons.selected-color")
    private static let deselectedTitleColor =
        RideOsRiderResourceLoader.instance.getColor("ai.rideos.rider.seat-selection.buttons.deselected-color")

    private let disposeBag = DisposeBag()

    private let stackView = SeatSelectionView.horizontalStackView()

    private let buttons = SeatSelectionView.seatCount.map { SeatSelectionView.button(forSeatCount: $0) }

    private var selectedSeatCountButton: UIButton?

    public private(set) var selectedSeatCount: UInt32 = SeatSelectionView.seatCount[0]

    public init() {
        super.init(frame: .zero)

        addSubview(stackView)
        activateMaxSizeConstraintsOnSubview(stackView)

        buttons.forEach { stackView.addArrangedSubview($0) }

        zip(buttons, SeatSelectionView.seatCount).forEach { button, seatCount in
            button.rx.tap
                .subscribe(onNext: { [unowned self] in
                    self.selectedSeatCount = seatCount
                    self.selectSeatCount(button: button)
                })
                .disposed(by: disposeBag)
        }

        selectSeatCount(button: buttons[0])
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    private func selectSeatCount(button: UIButton) {
        if let selectedSeatCountButton = selectedSeatCountButton {
            selectedSeatCountButton.setImage(SeatSelectionView.deselectedImage, for: .normal)
            selectedSeatCountButton.setTitleColor(SeatSelectionView.deselectedTitleColor, for: .normal)
        }
        button.setImage(SeatSelectionView.selectedImage, for: .normal)
        button.setTitleColor(SeatSelectionView.selectedTitleColor, for: .normal)
        selectedSeatCountButton = button
    }
}

extension SeatSelectionView {
    private static func horizontalStackView() -> UIStackView {
        let view = UIStackView()
        view.alignment = .fill
        view.distribution = .equalSpacing
        view.layoutMargins = UIEdgeInsets(top: 0.0, left: 26.0, bottom: 0.0, right: 26.0)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }

    private static func button(forSeatCount seatCount: UInt32) -> UIButton {
        let button = UIButton(type: .custom)

        let title = String(seatCount)
        let font = UIFont.systemFont(ofSize: 22)

        button.setImage(SeatSelectionView.deselectedImage, for: .normal)
        button.setTitle(title, for: .normal)
        button.setTitleColor(SeatSelectionView.deselectedTitleColor, for: .normal)
        button.titleLabel?.font = font

        // Center the button's title inside the image
        button.titleEdgeInsets = UIEdgeInsets(top: 0.0,
                                              left: -SeatSelectionView.selectedImage.size.width,
                                              bottom: 0.0,
                                              right: 0.0)
        button.imageEdgeInsets = UIEdgeInsets(
            top: 0.0,
            left: 0.0,
            bottom: 0.0,
            right: -NSAttributedString(string: title, attributes: [NSAttributedString.Key.font: font]).size().width
        )

        return button
    }
}
