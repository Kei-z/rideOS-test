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

import CoreLocation
import Foundation
import NMAKit
import RideOsCommon

public class HereMapView: UIMapView {
    public var mapInsets: UIEdgeInsets

    private let pixelsPerPoint: CGFloat
    private let mapView: NMAMapView
    private var mapCenterListener: MapCenterListener?
    private var mapDragListener: MapDragListener?
    private var nmaMarkers: [String: NMAMapMarker] = [:]
    private var nmaPolylines: [NMAMapPolyline] = []

    // Additional padding (on top of the safeAreaInsets + mapInsets to account for things like PUDO pins, etc.
    private static let additionalInsetPadding = UIEdgeInsets(top: 50, left: 25, bottom: 10, right: 25)

    public init(frame: CGRect = .zero,
                initialMapCenter: NMAGeoCoordinates = NMAGeoCoordinates(latitude: 0, longitude: 0),
                initialZoom: Float = 0,
                pixelsPerPoint: CGFloat = UIScreen.main.scale) {
        self.pixelsPerPoint = pixelsPerPoint
        mapView = NMAMapView(frame: frame)
        mapInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        super.init(frame: frame)

        mapView.set(geoCenter: initialMapCenter, animation: .none)
        mapView.zoomLevel = initialZoom

        mapView.delegate = self

        addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        mapView.positionIndicator.isVisible = true
        mapView.disableMapGestures(.rotate)
        mapView.disableMapGestures(.twoFingerPan)
        mapView.disableKinetic(forGestures: .rotate)
        mapView.projectionType = .mercator
        mapView.copyrightLogoPosition = .bottomRight
    }

    public func setMapCenterListener(_ mapCenterListener: MapCenterListener?) {
        self.mapCenterListener = mapCenterListener
    }

    public func setMapDragListener(_ mapDragListener: MapDragListener?) {
        self.mapDragListener = mapDragListener
    }

    public func setMapSettings(_ mapSettings: MapSettings) {
        mapView.positionIndicator.isVisible = mapSettings.shouldShowUserLocation
        mapView.mapCenterFixedOnRotateZoom = mapSettings.keepCenterWhileZooming
    }

    public func moveCamera(_ cameraUpdate: CameraUpdate) {
        switch cameraUpdate {
        case let .centerAndZoom(center, zoom):
            mapView.set(geoCenter: center.nmaGeoCoordinates(), zoomLevel: zoom, animation: .bow)
        case let .fitLatLngBounds(bounds):
            mapView.set(boundingBox: bounds.nmaGeoBoundingBox(), animation: .bow)
        }
    }

    public func showMarkers(_ markers: [String: DrawableMarker]) {
        let existingMarkerKeys = Set(nmaMarkers.keys)
        let updatedMarkerKeys = Set(markers.keys)

        let keysToAdd = updatedMarkerKeys.subtracting(existingMarkerKeys)
        let keysToRemove = existingMarkerKeys.subtracting(updatedMarkerKeys)
        let keysToUpdate = existingMarkerKeys.intersection(updatedMarkerKeys)

        // Add new markers
        for key in keysToAdd {
            let marker = markers[key]!
            let nmaMarker = NMAMapMarker(geoCoordinates: marker.coordinate.nmaGeoCoordinates(),
                                         image: marker.icon.image.rotated(byDegrees: CGFloat(marker.heading)))
            nmaMarker.anchorOffset = marker.icon.groundAnchor
            nmaMarkers[key] = nmaMarker
            mapView.add(mapObject: nmaMarker)
        }

        // Remove old markers
        for key in keysToRemove {
            mapView.remove(mapObject: nmaMarkers[key]!)
            nmaMarkers[key] = nil
        }

        // Update markers
        for key in keysToUpdate {
            let marker = markers[key]!, nmaMarker = nmaMarkers[key]!
            nmaMarker.coordinates = marker.coordinate.nmaGeoCoordinates()
            nmaMarker.icon = NMAImage(uiImage: marker.icon.image.rotated(byDegrees: CGFloat(marker.heading)))
            nmaMarker.anchorOffset = marker.icon.groundAnchor
        }
    }

    public func showPaths(_ paths: [DrawablePath]) {
        mapView.remove(mapObjects: nmaPolylines)
        nmaPolylines.removeAll()
        for path in paths {
            // TODO(chrism): Add support for dashed polylines
            let polyline = NMAMapPolyline(vertices: path.coordinates.map { $0.nmaGeoCoordinates() })
            polyline.lineColor = path.color
            polyline.lineWidth = UInt(path.width * Float(pixelsPerPoint))
            nmaPolylines.append(polyline)
        }
        mapView.add(mapObjects: nmaPolylines)
    }

    public var visibleRegion: LatLngBounds {
        return mapView.boundingBox!.latLngBounds()
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    private var effectiveInsets: UIEdgeInsets {
        let insets = UIEdgeInsets(
            top: mapInsets.top + safeAreaInsets.top + HereMapView.additionalInsetPadding.top,
            left: mapInsets.left + safeAreaInsets.left + HereMapView.additionalInsetPadding.left,
            bottom: mapInsets.bottom + safeAreaInsets.bottom + HereMapView.additionalInsetPadding.bottom,
            right: mapInsets.right + safeAreaInsets.right + HereMapView.additionalInsetPadding.right
        )
        return insets
    }
}

// MARK: NMAMapViewDelegate

extension HereMapView: NMAMapViewDelegate {
    public func mapViewDidEndMovement(_ mapView: NMAMapView) {
        mapCenterListener?.mapCenterDidMove(to: mapView.geoCenter.clLocationCoordinate2D())
    }

    public func mapViewDidBeginMovement(_: NMAMapView) {
        mapDragListener?.mapWasDragged()
    }
}
