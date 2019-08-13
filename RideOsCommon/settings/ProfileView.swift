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
import RxCocoa
import RxSwift
import RxSwiftExt

public class ProfileView: UIView {
    public static let backgroundColor =
        RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.settings.profile.color.background")
    private static let pictureTopInset: CGFloat = 28.0
    private static let pictureToNameVerticalSpacing: CGFloat = 16.0
    private static let textColor: UIColor = .white
    private static let nameFont = UIFont.systemFont(ofSize: 19.0)
    private static let emailFont = UIFont.systemFont(ofSize: 15.0)
    private static let nameToEmailVerticalSpacing: CGFloat = 8.0
    private static let profilePictureSize = CGSize(width: 64.0, height: 64.0)

    private static let fetchProfilePictureRepeatBehavior = RepeatBehavior.immediate(maxCount: 5)

    private let disposeBag = DisposeBag()
    private let pictureImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()

    private let schedulerProvider: SchedulerProvider
    private let urlSession: URLSession
    private let logger: Logger

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                urlSession: URLSession = URLSession.shared,
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.schedulerProvider = schedulerProvider
        self.urlSession = urlSession
        self.logger = logger

        super.init(frame: .zero)
        backgroundColor = ProfileView.backgroundColor

        addSubview(pictureImageView)
        pictureImageView.translatesAutoresizingMaskIntoConstraints = false
        pictureImageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor,
                                              constant: ProfileView.pictureTopInset).isActive = true
        pictureImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        pictureImageView.mask = UIImageView(image: CommonImages.userPhotoMask())

        addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.topAnchor.constraint(equalTo: pictureImageView.bottomAnchor,
                                       constant: ProfileView.pictureToNameVerticalSpacing).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        nameLabel.textAlignment = .center
        nameLabel.textColor = ProfileView.textColor
        nameLabel.font = ProfileView.nameFont

        addSubview(emailLabel)
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor,
                                        constant: ProfileView.nameToEmailVerticalSpacing).isActive = true
        emailLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        emailLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        emailLabel.textAlignment = .center
        emailLabel.textColor = ProfileView.textColor
        emailLabel.font = ProfileView.emailFont
    }

    public func set(pictureURL: URL) {
        URLSession.shared.rx.response(request: URLRequest(url: pictureURL))
            .observeOn(schedulerProvider.mainThread())
            .logErrors(logger: logger)
            .retry(ProfileView.fetchProfilePictureRepeatBehavior)
            .subscribe(onNext: { _, data in
                self.pictureImageView.image = UIImage(data: data)?.imageWith(newSize: ProfileView.profilePictureSize)
            })
            .disposed(by: disposeBag)
    }

    public func set(preferredName: String?) {
        nameLabel.text = preferredName
    }

    public func set(email: String?) {
        emailLabel.text = email
    }
}
