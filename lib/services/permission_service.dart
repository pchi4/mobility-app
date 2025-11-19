import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationStatus {
  granted, 
  denied, 
  disabled, 
  loading,
}

class PermissionService {
  LocationStatus _mapPermissionStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return LocationStatus.granted;
    } else if (status.isDenied || status.isPermanentlyDenied) {
      return LocationStatus.denied;
    }
    return LocationStatus.denied; 
  }

  Future<LocationStatus> checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationStatus.disabled;
    }

    PermissionStatus permission = await Permission.location.status;

    if (permission.isGranted || permission.isLimited) {
      return LocationStatus.granted;
    }

    if (permission.isDenied) {
      permission = await Permission.location.request();
    }

    if (permission.isGranted || permission.isLimited) {
      return LocationStatus.granted;
    } else if (permission.isPermanentlyDenied) {
      return LocationStatus.denied;
    }

    return _mapPermissionStatus(permission);
  }

  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}
