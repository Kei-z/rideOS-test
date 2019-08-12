# rideOS iOS SDK
## Overview
The rideOS iOS SDK provides foundations for running rider and driver applications for ride-hail using the rideOS APIs. These applications are intended to work out of the box, but with flexibility to customize easily.

## Running the Apps
To run the example rider or driver apps, see the relevant README ([rider](example_apps/rider/README.md), [driver](example_apps/driver/README.md)).

## Layout
The top-level directories are as follows:
- `example_apps` - example rider and driver apps. This is probably where you'll want to start.
- `RideOsRider` - the rider library has all of the view, controller, and navigation classes to run a rider app. Note that this doesn't actually create or run an app. See `example_apps/rider` for that.
- `RideOsDriver` - the driver library has all the view, controller, and navigation classes to run a driver app. Note that the driver library is currently in alpha.
- `RideOsCommon` - the common library contains utilities and shared resources between the rider and driver apps.
- `RideOsGoogleMaps` - Google Maps-based implementation of the maps-related protocols (ex: `GeocodeInteractor`) defined in `RideOsCommon`.
- `RideOsHereMaps` - work-in-progress HERE Maps-based implementation of the maps-related protocols (ex: `GeocodeInteractor`) defined in `RideOsCommon`.
- `RideOsTests` - unit tests for the libraries above.

## Licensing

### Code

All code is distributed under the [Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0) license.

### Assets

All assets (`*.png`, `*.jpg`, etc.) are distributed under the [Creative Commons Attribution 4.0 International](http://creativecommons.org/licenses/by/4.0/) license.

* Artist: Yen Ma
* Copyright: rideOS
