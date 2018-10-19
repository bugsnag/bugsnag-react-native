package com.garuth;

import android.widget.Toast;

import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

import java.util.Map;
import java.util.HashMap;

public class FancyModule extends ReactContextBaseJavaModule {

  public native int somethingInnocuousFromJNI(int input);

  public FancyModule(ReactApplicationContext reactContext) {
    super(reactContext);
  }

  @Override
  public String getName() {
    return "FancyExample";
  }

  @ReactMethod
  public void doTheThing() {
    somethingInnocuousFromJNI(34);
  }
}
