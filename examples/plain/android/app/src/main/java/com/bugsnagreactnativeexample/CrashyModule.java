package com.bugsnagreactnativeexample;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class CrashyModule extends ReactContextBaseJavaModule {

  static {
    System.loadLibrary("entrypoint");
  }

  public native void doCrash();

//  public native void notifyFromCXX();


  public CrashyModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @Override
  public String getName() {
    return "CrashyCrashy";
  }

  @ReactMethod
  public void generateCrash() throws Exception {
    doCrash();
//    throw new Exception("Ooopsy from Java!");
  }
}
