package com.bugsnag;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.lang.String;

import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.ReactPackage;
import com.facebook.react.uimanager.ViewManager;

import com.bugsnag.android.*;


public class BugsnagReactNative extends ReactContextBaseJavaModule {

  private ReactContext reactContext;

  public static ReactPackage getPackage() {
    return new BugsnagPackage();
  }

  public BugsnagReactNative(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "BugsnagReactNative";
  }

  @ReactMethod
  public void startWithOptions(ReadableMap options) {
      Bugsnag.init(this.reactContext, options.getString("apiKey"), true);
  }

  @ReactMethod
  public void leaveBreadcrumb(ReadableMap options) {
      Bugsnag.leaveBreadcrumb(options.getString("name"),
                              parseBreadcrumbType(options.getString("type")),
                              readStringMap(options.getMap("metadata")));
  }

  @ReactMethod
  public void notify(ReadableMap payload) {
      Exception exception = new Exception(payload.getString("errorMessage"));
      // parse stacktrace
      // merge metadata
      // set context
      // set groupingHash
      Bugsnag.notify(exception,
                     parseSeverity(payload.getString("severity")),
                     new MetaData(readObjectMap(payload.getMap("metadata"))));
  }

  @ReactMethod
  public void setUser(ReadableMap userInfo) {
      Bugsnag.setUser(userInfo.getString("id"),
                      userInfo.getString("name"),
                      userInfo.getString("email"));
  }

  /**
   * Convert a typed map into a string Map
   */
  Map<String, String> readStringMap(ReadableMap map) {
    Map output = new HashMap<String,String>();
    ReadableMapKeySetIterator iterator = map.keySetIterator();
    while (iterator.hasNextKey()) {
        String key = iterator.nextKey();
        ReadableMap pair = map.getMap(key);
        output.put(key, pair.getString("value"));
    }
    return output;
  }

  /**
   * Convert a typed map from JS into a Map
   */
  Map<String, Object> readObjectMap(ReadableMap map) {
    Map output = new HashMap<String, Object>();
    ReadableMapKeySetIterator iterator = map.keySetIterator();

    while (iterator.hasNextKey()) {
        String key = iterator.nextKey();
        ReadableMap pair = map.getMap(key);
        switch (pair.getString("type")) {
            case "boolean":
                output.put(key, pair.getBoolean("value"));
                break;
            case "number":
                output.put(key, pair.getDouble("value"));
                break;
            case "string":
                output.put(key, pair.getString("value"));
                break;
            case "map":
                output.put(key, readObjectMap(pair.getMap("value")));
                break;
        }
    }

    return output;
  }

  BreadcrumbType parseBreadcrumbType(String value) {
    for (BreadcrumbType type : BreadcrumbType.values()) {
        if (type.toString().equals(value)) {
            return type;
        }
    }
    return BreadcrumbType.MANUAL;
  }

  Severity parseSeverity(String value) {
      switch (value) {
        case "error": return Severity.ERROR;
        case "info": return Severity.INFO;
        case "warning":
        default:
            return Severity.WARNING;
      }
  }
}

class BugsnagPackage implements ReactPackage {

  @Override
  public List<Class<? extends JavaScriptModule>> createJSModules() {
    return Collections.emptyList();
  }

  @Override
  public List<ViewManager> createViewManagers(
          ReactApplicationContext reactContext) {
    return Collections.emptyList();
  }

  @Override
  public List<NativeModule> createNativeModules(
          ReactApplicationContext reactContext) {
    return Arrays.<NativeModule>asList(new BugsnagReactNative(reactContext));
  }
}
