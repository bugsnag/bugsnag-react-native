package com.bugsnag;

import android.app.Activity;
import android.content.Context;
import android.support.annotation.NonNull;

import com.bugsnag.android.BreadcrumbType;
import com.bugsnag.android.Bugsnag;
import com.bugsnag.android.Callback;
import com.bugsnag.android.Client;
import com.bugsnag.android.Configuration;
import com.bugsnag.android.JsonStream;
import com.bugsnag.android.MetaData;
import com.bugsnag.android.Report;
import com.bugsnag.android.Severity;
import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.uimanager.ViewManager;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;


public class BugsnagReactNative extends ReactContextBaseJavaModule {

  private ReactContext reactContext;
  private String libraryVersion;
  private String bugsnagAndroidVersion;
  final static Logger logger = Logger.getLogger("bugsnag-react-native");

  public static ReactPackage getPackage() {
    return new BugsnagPackage();
  }

  public static Client start(Context context) {
    Client client = Bugsnag.init(context);
    // The first session starts during JS initialization
    // Applications which have specific components in RN instead of the primary
    // way to interact with the application should instead leverage startSession
    // manually.
    client.setAutoCaptureSessions(false);
    return client;
  }

  public static Client startWithApiKey(Context context, String APIKey) {
    Client client = Bugsnag.init(context, APIKey);
    client.setAutoCaptureSessions(false);
    return client;
  }

  public static Client startWithConfiguration(Context context, Configuration config) {
    config.setAutoCaptureSessions(false);
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
  public void startSession() {
      Bugsnag.startSession();
  }

  @ReactMethod
  public void stopSession() {
      Bugsnag.stopSession();
  }

  @ReactMethod
  public void resumeSession() {
      Bugsnag.resumeSession();
  }

  @ReactMethod
  public void startWithOptions(ReadableMap options) {
      String apiKey = null;
      if (options.hasKey("apiKey")) {
          apiKey = options.getString("apiKey");
      }
      Client client = getClient(apiKey);
      libraryVersion = options.getString("version");
      bugsnagAndroidVersion = client.getClass().getPackage().getSpecificationVersion();
      configureRuntimeOptions(client, options);

      logger.info(String.format("Initialized Bugsnag React Native %s/Android %s",
                  libraryVersion,
                  bugsnagAndroidVersion));
  }

  @ReactMethod
  public void leaveBreadcrumb(ReadableMap options) {
      String name = options.getString("name");
      Bugsnag.leaveBreadcrumb(name,
                              parseBreadcrumbType(options.getString("type")),
                              readStringMap(options.getMap("metadata")));
  }


  @ReactMethod
  public void notify(ReadableMap payload, Promise promise) {
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

      logger.info(String.format("Sending exception: %s - %s %s\n",
                                errorClass, errorMessage, rawStacktrace));
      JavaScriptException exc = new JavaScriptException(errorClass,
                                                        errorMessage,
                                                        rawStacktrace);

      DiagnosticsCallback handler = new DiagnosticsCallback(libraryVersion,
                                                            bugsnagAndroidVersion,
                                                            payload);

      Map<String, Object> map = new HashMap<>();
      String severity = payload.getString("severity");
      String severityReason = payload.getString("severityReason");
      map.put("severity", severity);
      map.put("severityReason", severityReason);
      boolean blocking = payload.hasKey("blocking") && payload.getBoolean("blocking");

      Bugsnag.internalClientNotify(exc, map, blocking, handler);

      if (promise != null)
        promise.resolve(null);
  }

  @ReactMethod
  public void setUser(ReadableMap userInfo) {
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
    Map<String,String> output = new HashMap<>();
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

  private Client getClient(String apiKey) {
      Client client;
      try {
          client = Bugsnag.getClient();
      } catch (IllegalStateException exception) {
          if (apiKey != null) {
              client = Bugsnag.init(this.reactContext, apiKey);
          } else {
              client = Bugsnag.init(this.reactContext);
          }
      }
      return client;
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
      client.setIgnoreClasses("com.facebook.react.common.JavascriptException");
      Configuration config = client.getConfig();
      if (options.hasKey("appVersion")) {
          String version = options.getString("appVersion");
          if (version != null && version.length() > 0)
              client.setAppVersion(version);
      }

      String notify = null;
      String sessions = null;

      if (options.hasKey("endpoint")) {
          notify = options.getString("endpoint");
      }
      if (options.hasKey("sessionsEndpoint")) {
          sessions = options.getString("sessionsEndpoint");
      }

      if (notify != null && notify.length() > 0) {
          config.setEndpoints(notify, sessions);
      } else if (sessions != null && sessions.length() > 0) {
          logger.warning("The session tracking endpoint should not be set without the error reporting endpoint.");
      }


      if (options.hasKey("releaseStage")) {
          String releaseStage = options.getString("releaseStage");
          if (releaseStage != null && releaseStage.length() > 0)
              client.setReleaseStage(releaseStage);
      }

      if (options.hasKey("autoNotify")) {
          if (options.getBoolean("autoNotify")) {
              client.enableExceptionHandler();
          } else {
              client.disableExceptionHandler();
          }
      }

      if (options.hasKey("codeBundleId")) {
          String codeBundleId = options.getString("codeBundleId");
          if (codeBundleId != null && codeBundleId.length() > 0)
              client.addToTab("app", "codeBundleId", codeBundleId);
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
      if (options.hasKey("automaticallyCollectBreadcrumbs")) {
          boolean autoCapture = options.getBoolean("automaticallyCollectBreadcrumbs");
          config.setAutomaticallyCollectBreadcrumbs(autoCapture);
      }
      // Process session tracking last in case the effects of other options
      // should be captured as a part of the session
      if (options.hasKey("autoCaptureSessions")) {
          boolean autoCapture = options.getBoolean("autoCaptureSessions");
          config.setAutoCaptureSessions(autoCapture);
          if (autoCapture) {
              // The launch event session is skipped because autoCaptureSessions
              // was not set when Bugsnag was first initialized. Manually sending a
              // session to compensate.
              client.startSession();
          }
      }
  }
}

class BugsnagPackage implements ReactPackage {

  public List<Class<? extends JavaScriptModule>> createJSModules() {
    return Collections.emptyList();
  }

  @SuppressWarnings("rawtypes") // the ReactPackage interface uses a raw type, ignore it
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
        Map<String, Object> output = new HashMap<>();
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
        report.getNotifier().setName(NOTIFIER_NAME);
        report.getNotifier().setURL(NOTIFIER_URL);
        report.getNotifier().setVersion(String.format("%s (Android %s)",
                                                libraryVersion,
                                                bugsnagAndroidVersion));

        if (groupingHash != null && groupingHash.length() > 0)
            report.getError().setGroupingHash(groupingHash);
        if (context != null && context.length() > 0)
            report.getError().setContext(context);
        if (metadata != null) {
            MetaData reportMetadata = report.getError().getMetaData();
            for (String tab : metadata.keySet()) {
                Object value = metadata.get(tab);

                if (value instanceof Map) {
                    @SuppressWarnings("unchecked") // ignore type erasure when casting Map
                    Map<String, Object> values = (Map<String, Object>) value;

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
    private static final long serialVersionUID = 1175784680140218622L;

    private final String name;
    private final String rawStacktrace;

    JavaScriptException(String name, String message, String rawStacktrace) {
        super(message);
        this.name = name;
        this.rawStacktrace = rawStacktrace;
    }

    public void toStream(@NonNull JsonStream writer) throws IOException {
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
