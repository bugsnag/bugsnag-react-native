package com.bugsnag;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.lang.String;
import java.lang.NumberFormatException;
import java.io.IOException;

import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.ReactPackage;
import com.facebook.react.uimanager.ViewManager;

import com.bugsnag.android.*;


public class BugsnagReactNative extends ReactContextBaseJavaModule {

  private ReactContext reactContext;
  private String libraryVersion;
  private String bugsnagAndroidVersion;

  public static ReactPackage getPackage() {
    return new BugsnagPackage();
  }

  public BugsnagReactNative(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    libraryVersion = null;
    bugsnagAndroidVersion = null;
  }

  @Override
  public String getName() {
    return "BugsnagReactNative";
  }

  @ReactMethod
  public void startWithOptions(ReadableMap options) {
      libraryVersion = options.getString("version");
      Configuration config = createConfiguration(options);
      bugsnagAndroidVersion = config.getClass().getPackage().getSpecificationVersion();

      Bugsnag.init(this.reactContext, config);
  }

  @ReactMethod
  public void leaveBreadcrumb(ReadableMap options) {
      Bugsnag.leaveBreadcrumb(options.getString("name"),
                              parseBreadcrumbType(options.getString("type")),
                              readStringMap(options.getMap("metadata")));
  }

  @ReactMethod
  public void notify(ReadableMap payload) {
      JavaScriptException exc = new JavaScriptException(payload.getString("errorClass"),
                                                        payload.getString("errorMessage"),
                                                        payload.getString("stacktrace"));

      Bugsnag.notify(exc, new DiagnosticsCallback(libraryVersion,
                                                  bugsnagAndroidVersion,
                                                  payload));
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
  private Map<String, String> readStringMap(ReadableMap map) {
    Map output = new HashMap<String,String>();
    ReadableMapKeySetIterator iterator = map.keySetIterator();
    while (iterator.hasNextKey()) {
        String key = iterator.nextKey();
        ReadableMap pair = map.getMap(key);
        output.put(key, pair.getString("value"));
    }
    return output;
  }

  private BreadcrumbType parseBreadcrumbType(String value) {
    for (BreadcrumbType type : BreadcrumbType.values()) {
        if (type.toString().equals(value)) {
            return type;
        }
    }
    return BreadcrumbType.MANUAL;
  }

  private Configuration createConfiguration(ReadableMap options) {
      Configuration config = new Configuration(options.getString("apiKey"));

      if (options.hasKey("endpoint")) {
          String endpoint = options.getString("endpoint");
          if (endpoint != null && endpoint.length() > 0)
              config.setEndpoint(endpoint);
      }

      if (options.hasKey("releaseStage")) {
          String releaseStage = options.getString("releaseStage");
          if (releaseStage != null && releaseStage.length() > 0)
              config.setReleaseStage(releaseStage);
      }

      if (options.hasKey("notifyReleaseStages")) {
          ReadableArray stages = options.getArray("notifyReleaseStages");
          if (stages != null && stages.size() > 0) {
              String releaseStages[] = new String[stages.size()];
              for (int i = 0; i < stages.size(); i++) {
                releaseStages[i] = stages.getString(i);
              }
              config.setNotifyReleaseStages(releaseStages);
          }
      }

      return config;
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

/**
 * Attaches report diagnostics before delivery
 */
class DiagnosticsCallback implements Callback {
    static final String NOTIFIER_NAME = "Bugsnag for React Native";
    static final String NOTIFIER_URL = "https://github.com/bugsnag/bugsnag-react-native";

    final private Severity severity;
    final private String context;
    final private String groupingHash;
    final private Map<String, Object> metadata;
    final private String libraryVersion;
    final private String bugsnagAndroidVersion;

    DiagnosticsCallback(String libraryVersion,
                        String bugsnagAndroidVersion,
                        ReadableMap payload) {
        this.libraryVersion = libraryVersion;
        this.bugsnagAndroidVersion = bugsnagAndroidVersion;
        severity = parseSeverity(payload.getString("severity"));
        metadata = readObjectMap(payload.getMap("metadata"));

        if (payload.hasKey("context"))
            context = payload.getString("context");
        else
            context = null;

        if (payload.hasKey("groupingHash"))
            groupingHash = payload.getString("groupingHash");
        else
            groupingHash = null;

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

    @Override
    public void beforeNotify(Report report) {
        report.setNotifierName(NOTIFIER_NAME);
        report.setNotifierURL(NOTIFIER_URL);
        report.setNotifierVersion(String.format("%s (Android %s)",
                                                libraryVersion,
                                                bugsnagAndroidVersion));

        report.getError().setSeverity(severity);
        if (groupingHash != null && groupingHash.length() > 0)
            report.getError().setGroupingHash(groupingHash);
        if (context != null && context.length() > 0)
            report.getError().setContext(context);
        if (metadata != null) {
            MetaData reportMetadata = report.getError().getMetaData();
            for (String tab : metadata.keySet()) {
                Object value = metadata.get(tab);
                if (value instanceof Map) {
                    Map<String, Object> values = (Map<String, Object>)value;
                    for (String key : values.keySet()) {
                        reportMetadata.addToTab(tab, key, values.get(key));
                    }
                }
            }
        }
    }
}

/**
 * Creates a streamable exception with a JavaScript stacktrace
 */
class JavaScriptException extends Exception implements JsonStream.Streamable {
    private final String name;
    private final String rawStacktrace;

    JavaScriptException(String name, String message, String rawStacktrace) {
        super(message);
        this.name = name;
        this.rawStacktrace = rawStacktrace;
    }

    public void toStream(JsonStream writer) throws IOException {
        writer.name("errorClass").value(name);
        writer.name("message").value(getLocalizedMessage());

        writer.name("stacktrace");
        writer.beginArray();
        for (String rawFrame : rawStacktrace.split("\\n")) {
            String methodComponents[] = rawFrame.split("@");
            if (methodComponents.length == 2) {
                String components[] = methodComponents[1].split(":");
                if (components.length == 3) {
                    int columnNumber = 0;
                    int lineNumber = 0;
                    try {
                        columnNumber = Integer.parseInt(components[2]);
                        lineNumber = Integer.parseInt(components[1]);
                    } catch (NumberFormatException e) {
                        continue;
                    }
                    writer.beginObject();
                        writer.name("method").value(methodComponents[0]);
                        writer.name("columnNumber").value(columnNumber);
                        writer.name("lineNumber").value(lineNumber);
                        writer.name("file").value(components[0]);
                    writer.endObject();
                } else {
                    throw new IOException(methodComponents[1]);
                }
            } else {
                throw new IOException(rawFrame);
            }
        }
        writer.endArray();
    }
}
