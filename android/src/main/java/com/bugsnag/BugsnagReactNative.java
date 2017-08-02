package com.bugsnag;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.logging.Logger;
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

import android.content.Context;

import com.bugsnag.android.*;


public class BugsnagReactNative extends ReactContextBaseJavaModule {

  private ReactContext reactContext;
  private String libraryVersion;
  private String bugsnagAndroidVersion;
  final static Logger logger = Logger.getLogger("bugsnag-react-native");

  public static ReactPackage getPackage() {
    return new BugsnagPackage();
  }

  public static Client start(Context context) {
    return Bugsnag.init(context);
  }

  public static Client startWithApiKey(Context context, String APIKey) {
    return Bugsnag.init(context, APIKey);
  }

  public static Client startWithConfiguration(Context context, Configuration config) {
    return Bugsnag.init(context, config);
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
      Client client = null;
      if (options.hasKey("apiKey")) {
          client = Bugsnag.init(this.reactContext, options.getString("apiKey"));
      } else {
          client = Bugsnag.init(this.reactContext);
      }
      bugsnagAndroidVersion = client.getClass().getPackage().getSpecificationVersion();
      configureRuntimeOptions(client, options);

      logger.info(String.format("Initialized Bugsnag React Native %s/Android %s",
                  libraryVersion,
                  bugsnagAndroidVersion));
  }

  @ReactMethod
  public void leaveBreadcrumb(ReadableMap options) {
      String name = options.getString("name");
      logger.info(String.format("Leaving breadcrumb '%s'", name));
      Bugsnag.leaveBreadcrumb(name,
                              parseBreadcrumbType(options.getString("type")),
                              readStringMap(options.getMap("metadata")));
  }

  @ReactMethod
  public void notify(ReadableMap payload) {
      notifyBlocking(payload, false, null);
  }

  @ReactMethod
  public void notifyBlocking(ReadableMap payload, boolean blocking, com.facebook.react.bridge.Callback callback) {
      if (!payload.hasKey("errorClass")) {
          logger.warning("Bugsnag could not notify: No error class");
          return;
      }
      if (!payload.hasKey("stacktrace")) {
          logger.warning("Bugsnag could not notify: No stacktrace");
          return;
      }
      final String errorClass = payload.getString("errorClass");
      final String errorMessage = payload.getString("errorMessage");
      final String rawStacktrace = payload.getString("stacktrace");

      logger.info(String.format("Sending exception: %s - %s\n",
                                errorClass, errorMessage, rawStacktrace));
      JavaScriptException exc = new JavaScriptException(errorClass,
                                                        errorMessage,
                                                        rawStacktrace);


      DiagnosticsCallback handler = new DiagnosticsCallback(libraryVersion,
                                                            bugsnagAndroidVersion,
                                                            payload);
      if (blocking) {
        Bugsnag.getClient().notifyBlocking(exc, handler);
      } else {
        Bugsnag.notify(exc, handler);
      }
      if (callback != null)
        callback.invoke();
  }

  @ReactMethod
  public void setUser(ReadableMap userInfo) {
      logger.info("Setting user data");
      String userId = userInfo.hasKey("id") ? userInfo.getString("id") : null;
      String email = userInfo.hasKey("email") ? userInfo.getString("email") : null;
      String name = userInfo.hasKey("name") ? userInfo.getString("name") : null;
      Bugsnag.setUser(userId, email, name);
  }

  @ReactMethod
  public void clearUser() {
      Bugsnag.clearUser();
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
        switch (pair.getString("type")) {
            case "boolean":
                output.put(key, String.valueOf(pair.getBoolean("value")));
                break;
            case "number":
                output.put(key, String.valueOf(pair.getDouble("value")));
                break;
            case "string":
                output.put(key, pair.getString("value"));
                break;
            case "map":
                output.put(key, String.valueOf(readStringMap(pair.getMap("value"))));
                break;
        }
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

  private void configureRuntimeOptions(Client client, ReadableMap options) {
      client.setIgnoreClasses(new String[] {"com.facebook.react.common.JavascriptException"});
      if (options.hasKey("appVersion")) {
          String version = options.getString("appVersion");
          if (version != null && version.length() > 0)
              client.setAppVersion(version);
      }

      if (options.hasKey("endpoint")) {
          String endpoint = options.getString("endpoint");
          if (endpoint != null && endpoint.length() > 0)
              client.setEndpoint(endpoint);
      }

      if (options.hasKey("releaseStage")) {
          String releaseStage = options.getString("releaseStage");
          if (releaseStage != null && releaseStage.length() > 0)
              client.setReleaseStage(releaseStage);
      }

      if (options.hasKey("notifyReleaseStages")) {
          ReadableArray stages = options.getArray("notifyReleaseStages");
          if (stages != null && stages.size() > 0) {
              String releaseStages[] = new String[stages.size()];
              for (int i = 0; i < stages.size(); i++) {
                releaseStages[i] = stages.getString(i);
              }
              client.setNotifyReleaseStages(releaseStages);
          }
      }
  }
}

class BugsnagPackage implements ReactPackage {

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
    private static final String EXCEPTION_TYPE = "browserjs";
    private final String name;
    private final String rawStacktrace;

    JavaScriptException(String name, String message, String rawStacktrace) {
        super(message);
        this.name = name;
        this.rawStacktrace = rawStacktrace;
    }

    public void toStream(JsonStream writer) throws IOException {
        BugsnagReactNative.logger.info("Serializing exception");
        writer.beginObject();
        writer.name("errorClass").value(name);
        writer.name("message").value(getLocalizedMessage());
        writer.name("type").value(EXCEPTION_TYPE);

        writer.name("stacktrace");
        writer.beginArray();
        for (String rawFrame : rawStacktrace.split("\\n")) {
            writer.beginObject();
            String methodComponents[] = rawFrame.split("@", 2);
            String fragment = methodComponents[0];
            if (methodComponents.length == 2) {
                writer.name("method").value(methodComponents[0]);
                fragment = methodComponents[1];
            }

            int columnIndex = fragment.lastIndexOf(":");
            if (columnIndex != -1) {
                String columnString = fragment.substring(columnIndex + 1, fragment.length());
                try {
                    int columnNumber = Integer.parseInt(columnString);
                    writer.name("columnNumber").value(columnNumber);
                } catch (NumberFormatException e) {
                    BugsnagReactNative.logger.info(String.format(
                                "Failed to parse column: '%s'",
                                columnString));
                }
                fragment = fragment.substring(0, columnIndex);
            }

            int lineNumberIndex = fragment.lastIndexOf(":");
            if (lineNumberIndex != -1) {
                String lineNumberString = fragment.substring(lineNumberIndex + 1, fragment.length());
                try {
                    int lineNumber = Integer.parseInt(lineNumberString);
                    writer.name("lineNumber").value(lineNumber);
                } catch (NumberFormatException e) {
                    BugsnagReactNative.logger.info(String.format(
                                "Failed to parse lineNumber: '%s'",
                                lineNumberString));
                }
                fragment = fragment.substring(0, lineNumberIndex);
            }

            writer.name("file").value(fragment);
            writer.endObject();
        }
        writer.endArray();
        writer.endObject();
    }
}
