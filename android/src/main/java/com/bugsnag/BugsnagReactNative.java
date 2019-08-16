package com.bugsnag;

import com.bugsnag.BugsnagReactNative;
import com.bugsnag.android.BreadcrumbType;
import com.bugsnag.android.Bugsnag;
import com.bugsnag.android.Client;
import com.bugsnag.android.Configuration;
import com.bugsnag.android.InternalHooks;
import com.bugsnag.android.JavaScriptException;

import android.content.Context;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;

import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

public class BugsnagReactNative extends ReactContextBaseJavaModule {

    private ReactContext reactContext;
    private String libraryVersion;
    private String bugsnagAndroidVersion;
    public static final Logger logger = Logger.getLogger("bugsnag-react-native");

    public static ReactPackage getPackage() {
        return new BugsnagPackage();
    }

    /**
     * Instantiates a bugsnag client using the API key in the AndroidManifest.xml
     *
     * @param context the application context
     * @return the bugsnag client
     */
    public static Client start(Context context) {
        Client client = Bugsnag.init(context);
        // The first session starts during JS initialization
        // Applications which have specific components in RN instead of the primary
        // way to interact with the application should instead leverage startSession
        // manually.
        client.setAutoCaptureSessions(false);
        return client;
    }

    /**
     * Instantiates a bugsnag client with a given API key.
     *
     * @param context the application context
     * @param apiKey the api key for your project
     * @return the bugsnag client
     */
    public static Client startWithApiKey(Context context, String apiKey) {
        Client client = Bugsnag.init(context, apiKey);
        client.setAutoCaptureSessions(false);
        return client;
    }

    /**
     * Instantiates a bugsnag client with a given configuration object.
     *
     * @param context the application context
     * @param config configuration for how bugsnag should behave
     * @return the bugsnag client
     */
    public static Client startWithConfiguration(Context context, Configuration config) {
        config.setAutoCaptureSessions(false);
        return Bugsnag.init(context, config);
    }

    /**
     * Instantiates the bugsnag react native module
     */
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

    /**
     * Configures the bugsnag client with configuration options from the JS layer, starting a new
     * client if one has not already been created.
     *
     * @param options the JS configuration object
     */
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
        InternalHooks.configureClient(client);

        logger.info(String.format("Initialized Bugsnag React Native %s/Android %s",
                libraryVersion,
                bugsnagAndroidVersion));
    }

    /**
     * Leaves a breadcrumb from the JS layer.
     *
     * @param options the JS breadcrumb
     */
    @ReactMethod
    public void leaveBreadcrumb(ReadableMap options) {
        String name = options.getString("name");
        Bugsnag.leaveBreadcrumb(name,
                parseBreadcrumbType(options.getString("type")),
                readStringMap(options.getMap("metadata")));
    }

    /**
     * Notifies the native client that a JS error occurred. Upon invoking this method, an
     * error report will be generated and delivered via the native client.
     *
     * @param payload information about the JS error
     * @param promise a nullable JS promise that is resolved after a report is delivered
     */
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

        if (promise != null) {
            promise.resolve(null);
        }
    }

    /**
     * Sets a user from the JS layer.
     *
     * @param userInfo the JS user
     */
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
        Map<String, String> output = new HashMap<>();
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
                default:
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
            if (version != null && version.length() > 0) {
                client.setAppVersion(version);
            }
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
            logger.warning("The session tracking endpoint should not be set "
                    + "without the error reporting endpoint.");
        }


        if (options.hasKey("releaseStage")) {
            String releaseStage = options.getString("releaseStage");
            if (releaseStage != null && releaseStage.length() > 0) {
                client.setReleaseStage(releaseStage);
            }
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
            if (codeBundleId != null && codeBundleId.length() > 0) {
                client.addToTab("app", "codeBundleId", codeBundleId);
            }
        }

        if (options.hasKey("notifyReleaseStages")) {
            ReadableArray stages = options.getArray("notifyReleaseStages");
            if (stages != null && stages.size() > 0) {
                String[] releaseStages = new String[stages.size()];
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
                client.resumeSession();
            }
        }
    }
}
