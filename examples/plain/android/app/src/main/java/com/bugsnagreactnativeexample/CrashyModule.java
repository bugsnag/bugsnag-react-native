package com.bugsnagreactnativeexample;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class CrashyModule extends ReactContextBaseJavaModule {
  // Used to load the 'native-lib' library on application startup.
  static {
    System.loadLibrary("native-lib");
  }

  /**
   * A native method that is implemented by the 'native-lib' native library,
   * which is packaged with this application.
   */
  public native String stringFromJNI();

  public CrashyModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @Override
  public String getName() {
    return "CrashyCrashy";
  }

  @ReactMethod
  public void generateCrash() throws Exception {
    String contents = stringFromJNI();
    throw new Exception(contents);
  }
}
