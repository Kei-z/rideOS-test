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
import GoogleMaps
import RideOsCommon

public class GoogleMapView: UIMapView {
    // Additional padding (on top of the safeAreaInsets + mapInsets to account for things like PUDO pins, etc.
    private static let additionalInsetPadding = UIEdgeInsets(top: 50, left: 25, bottom: 10, right: 25)
    public static let defaultCamera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 0)

    private var mapCenterListener: MapCenterListener?
    private var mapDragListener: MapDragListener?
    private var gmsPolylines: [GMSPolyline] = []
    private var gmsMarkers: [String: GMSMarker] = [:]

    private let mapView: GMSMapView

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(frame: CGRect = .zero,
                camera: GMSCameraPosition = GoogleMapView.defaultCamera) {
        mapView = GMSMapView.map(withFrame: frame, camera: camera)

        super.init(frame: frame)

        mapView.delegate = self

        addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        mapView.isMyLocationEnabled = true

        mapView.settings.myLocationButton = false
        mapView.settings.rotateGestures = false
        mapView.settings.tiltGestures = false
        mapView.settings.compassButton = false
        mapView.settings.indoorPicker = false
    }

    public var mapInsets = UIEdgeInsets.zero

    public func setMapCenterListener(_ mapCenterListener: MapCenterListener?) {
        self.mapCenterListener = mapCenterListener
    }

    public func setMapDragListener(_ mapDragListener: MapDragListener?) {
        self.mapDragListener = mapDragListener
    }

    private var effectiveInsets: UIEdgeInsets {
        let insets = UIEdgeInsets(
            top: mapInsets.top + safeAreaInsets.top + GoogleMapView.additionalInsetPadding.top,
            left: mapInsets.left + safeAreaInsets.left + GoogleMapView.additionalInsetPadding.left,
            bottom: mapInsets.bottom + safeAreaInsets.bottom + GoogleMapView.additionalInsetPadding.bottom,
            right: mapInsets.right + safeAreaInsets.right + GoogleMapView.additionalInsetPadding.right
        )
        return insets
    }

    public func setMapSettings(_ mapSettings: MapSettings) {
        mapView.isMyLocationEnabled = mapSettings.shouldShowUserLocation
        mapView.settings.allowScrollGesturesDuringRotateOrZoom = !mapSettings.keepCenterWhileZooming
    }

    public func moveCamera(_ cameraUpdate: CameraUpdate) {
        switch cameraUpdate {
        case let .centerAndZoom(center, zoom):
            mapView.animate(to: GMSCameraPosition(target: center, zoom: zoom))
        case let .fitLatLngBounds(bounds):
            guard let camera = mapView.camera(for: GMSCoordinateBounds(coordinate: bounds.northEastCorner,
                                                                       coordinate: bounds.southWestCorner),
                                              insets: effectiveInsets) else {
                return
            }
            mapView.animate(to: camera)
        }
    }

    public func showPaths(_ paths: [DrawablePath]) {
        removePolylines()
        for path in paths {
            let mutablePath = GMSMutablePath()
            for coordinate in path.coordinates {
                mutablePath.add(coordinate)
            }
            let polyline = GMSPolyline(path: mutablePath)
            polyline.strokeColor = path.color
            polyline.strokeWidth = CGFloat(path.width)
            if path.isDashed {
                polyline.spans = dashedSpans(forPolyline: polyline)
            } else {
                polyline.spans = nil
            }
            polyline.map = mapView
            gmsPolylines.append(polyline)
        }
    }

    private func dashedSpans(forPolyline polyline: GMSPolyline) -> [GMSStyleSpan] {
        let scale = Float(1.0 / mapView.projection.points(forMeters: 1, at: mapView.camera.target))
        let styles: [GMSStrokeStyle] = [.solidColor(polyline.strokeColor), .solidColor(.clear)]
        let solidLine = NSNumber(value: 10.0 * scale)
        let gap = NSNumber(value: 10.0 * scale)
        let lengths = [solidLine, gap]

        return GMSStyleSpans(polyline.path!, styles, lengths, GMSLengthKind.rhumb)
    }

    public func showMarkers(_ markers: [String: DrawableMarker]) {
        let existingMarkerKeys = Set(gmsMarkers.keys)
        let updatedMarkerKeys = Set(markers.keys)

        let keysToAdd = updatedMarkerKeys.subtracting(existingMarkerKeys)
        let keysToRemove = existingMarkerKeys.subtracting(updatedMarkerKeys)
        let keysToUpdate = existingMarkerKeys.intersection(updatedMarkerKeys)

        // Add new markers
        for key in keysToAdd {
            let marker = markers[key]!
            let gmsMarker = GMSMarker(position: marker.coordinate)
            gmsMarker.rotation = marker.heading
            gmsMarker.icon = marker.icon.image
            gmsMarker.map = mapView
            gmsMarker.groundAnchor = marker.icon.groundAnchor
            gmsMarkers[key] = gmsMarker
        }

        // Remove old markers
        for key in keysToRemove {
            gmsMarkers[key]!.map = nil
            gmsMarkers[key] = nil
        }

        // Update markers
        for key in keysToUpdate {
            let marker = markers[key]!, gmsMarker = gmsMarkers[key]!
            gmsMarker.position = marker.coordinate
            gmsMarker.rotation = marker.heading
            gmsMarker.icon = marker.icon.image
            gmsMarker.groundAnchor = marker.icon.groundAnchor
        }
    }

    private func removePolylines() {
        for polyline in gmsPolylines {
            polyline.map = nil
        }

        gmsPolylines.removeAll()
    }

    public var visibleRegion: LatLngBounds {
        let visibleRegion = mapView.projection.visibleRegion()
        let latitudes = [visibleRegion.farLeft.latitude,
                         visibleRegion.farRight.latitude,
                         visibleRegion.nearLeft.latitude,
                         visibleRegion.nearRight.latitude]
        let longitudes = [visibleRegion.farLeft.longitude,
                          visibleRegion.farRight.longitude,
                          visibleRegion.nearLeft.longitude,
                          visibleRegion.nearRight.longitude]
        return LatLngBounds(
            southWestCorner: CLLocationCoordinate2D(latitude: latitudes.min()!, longitude: longitudes.min()!),
            northEastCorner: CLLocationCoordinate2D(latitude: latitudes.max()!, longitude: longitudes.max()!)
        )
    }
}

// MARK: GMSMapViewDelegate

extension GoogleMapView: GMSMapViewDelegate {
    public func mapView(_: GMSMapView, idleAt position: GMSCameraPosition) {
        mapCenterListener?.mapCenterDidMove(to: position.target)
    }

    public func mapView(_: GMSMapView, willMove gesture: Bool) {
        if gesture {
            mapDragListener?.mapWasDragged()
        }
    }

    public func mapView(_: GMSMapView, didChange _: GMSCameraPosition) {
        // Re-compute polyline spans for the new zoom
        for polyline in gmsPolylines where polyline.spans != nil {
            polyline.spans = dashedSpans(forPolyline: polyline)
        }
    }
}
