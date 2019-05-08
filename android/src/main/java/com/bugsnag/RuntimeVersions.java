package com.bugsnag;

import com.facebook.react.modules.systeminfo.ReactNativeVersion;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class RuntimeVersions {

  public static void addRuntimeVersions(Map<String, Object> device) {
    @SuppressWarnings("unchecked") // ignore type erasure when casting Map
    Map<String, Object> runtimeVersions = (Map<String, Object>) device.get("runtimeVersions");

    if (runtimeVersions == null) {
        runtimeVersions = new HashMap<String, Object>();
        device.put("runtimeVersions", runtimeVersions);
    }
    runtimeVersions.put("reactNative", findReactNativeVersion());
  }

  // see https://github.com/facebook/react-native/blob/6df2edeb2a33d529e4b13a5b6767f300d08aeb0a/scripts/bump-oss-version.js
  private static String findReactNativeVersion() {
    String major = getStringSafe("major", ReactNativeVersion.VERSION);
    String minor = getStringSafe("minor", ReactNativeVersion.VERSION);
    String patch = getStringSafe("patch", ReactNativeVersion.VERSION);
    String prerelease = getStringSafe("prerelease", ReactNativeVersion.VERSION);
    StringBuilder sb = new StringBuilder();

    if (major != null) {
        sb.append(major);
        sb.append(".");
    }
    if (minor != null) {
        sb.append(minor);
        sb.append(".");
    }
    if (patch != null) {
        sb.append(patch);
    }
    if (prerelease != null) {
        sb.append("-");
        sb.append(prerelease);
    }
    return sb.toString();
  }

  private static String getStringSafe(String key, Map<String, Object> map) {
    Object obj = map.get(key);
    return (obj != null) ? obj.toString() : null;
  }
}