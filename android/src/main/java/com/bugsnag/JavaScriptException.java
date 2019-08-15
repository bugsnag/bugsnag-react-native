package com.bugsnag.android;

import com.bugsnag.BugsnagReactNative;
import com.bugsnag.android.JsonStream;

import java.io.IOException;

/**
 * Creates a streamable exception with a JavaScript stacktrace
 */
public class JavaScriptException extends BugsnagException implements JsonStream.Streamable {

    private static final String EXCEPTION_TYPE = "browserjs";
    private static final long serialVersionUID = 1175784680140218622L;

    private final String rawStacktrace;

    /**
     * Constructs a JavaScript exception - intended for internal use only.
     */
    public JavaScriptException(String name, String message, String rawStacktrace) {
        super(name, message, new StackTraceElement[]{}); // stacktrace set later on
        super.setType(EXCEPTION_TYPE);
        this.rawStacktrace = rawStacktrace;
    }

    @Override
    public void toStream(JsonStream writer) throws IOException {
        writer.beginObject();
        writer.name("errorClass").value(getName());
        writer.name("message").value(getMessage());
        writer.name("type").value(getType());

        writer.name("stacktrace");
        writer.beginArray();
        for (String rawFrame : rawStacktrace.split("\\n")) {
            writer.beginObject();
            String[] methodComponents = rawFrame.split("@", 2);
            String fragment = methodComponents[0];
            if (methodComponents.length == 2) {
                writer.name("method").value(methodComponents[0]);
                fragment = methodComponents[1];
            }

            int columnIndex = fragment.lastIndexOf(":");
            if (columnIndex != -1) {
                String columnString = fragment.substring(columnIndex + 1);
                try {
                    int columnNumber = Integer.parseInt(columnString);
                    writer.name("columnNumber").value(columnNumber);
                } catch (NumberFormatException exc) {
                    BugsnagReactNative.logger.info(String.format(
                            "Failed to parse column: '%s'",
                            columnString));
                }
                fragment = fragment.substring(0, columnIndex);
            }

            int lineNumberIndex = fragment.lastIndexOf(":");
            if (lineNumberIndex != -1) {
                String lineNumberString = fragment.substring(lineNumberIndex + 1);
                try {
                    int lineNumber = Integer.parseInt(lineNumberString);
                    writer.name("lineNumber").value(lineNumber);
                } catch (NumberFormatException exc) {
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
