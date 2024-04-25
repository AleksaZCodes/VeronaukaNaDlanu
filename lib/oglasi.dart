import 'dart:io';

class Oglasi {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8256185447075142/1372202434';
      // } else if (Platform.isIOS) {
      //   return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw new UnsupportedError('Unsupported platform');
    }
  }

  static String get bannerMolitveAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8256185447075142/4189937469';
      // } else if (Platform.isIOS) {
      //   return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw new UnsupportedError('Unsupported platform');
    }
  }

  static String get bannerBiblijaAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-8256185447075142/9250692453';
      // } else if (Platform.isIOS) {
      //   return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw new UnsupportedError('Unsupported platform');
    }
  }

  // static String get interstitialAdUnitId {
  //   if (Platform.isAndroid) {
  //     return "ca-app-pub-3940256099942544/1033173712";
  //   // } else if (Platform.isIOS) {
  //   //   return "ca-app-pub-3940256099942544/4411468910";
  //   } else {
  //     throw new UnsupportedError("Unsupported platform");
  //   }
  // }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-8256185447075142/6802899228";
      // } else if (Platform.isIOS) {
      //   return "ca-app-pub-3940256099942544/1712485313";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-3940256099942544/2247696110";
      // } else if (Platform.isIOS) {
      //   return "ca-app-pub-3940256099942544/1712485313";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }
}
