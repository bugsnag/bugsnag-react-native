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

        // this regex matches hermes-style stacktraces containing frames such as
        //   "    at v (address at index.android.bundle:2:1474)"
        // and
        //   "    at verify (http://10.0.2.2:8081/index.bundle?platform=android&dev=true&minify=false:250:14)"
        String hermesStacktraceFormatRe = "(?s).*\\sat .* \\(.*\\d+:\\d+\\)\\s.*";

        boolean isHermes = rawStacktrace.matches(hermesStacktraceFormatRe);
        for (String frame : rawStacktrace.split("\\n")) {
            if (isHermes) {
                serialiseHermesFrame(writer, frame.trim());
            } else {
                serialiseJsCoreFrame(writer, frame.trim());
            }
        }

        writer.endArray();
        writer.endObject();
    }

    private void serialiseJsCoreFrame(JsonStream writer, String frame) throws IOException {
        // expected format is as follows:
        //   release:
        //     "$method@$filename:$lineNumber:$columnNumber"
        //   dev:
        //     "$method@?uri:$lineNumber:$columnNumber"

        writer.beginObject();
        String[] methodComponents = frame.split("@", 2);
        String fragment = methodComponents[0];
        if (methodComponents.length == 2) {
            writer.name("method").value(methodComponents[0]);
            fragment = methodComponents[1];
        }

        int columnIndex = fragment.lastIndexOf(":");
        if (columnIndex != -1) {
            String columnString = fragment.substring(columnIndex + 1);
            Integer columnNumber = parseIntSafe(columnString);

            if (columnNumber != null) {
                writer.name("columnNumber").value(columnNumber);
            }
            fragment = fragment.substring(0, columnIndex);
        }

        int lineNumberIndex = fragment.lastIndexOf(":");
        if (lineNumberIndex != -1) {
            String lineNumberString = fragment.substring(lineNumberIndex + 1);
            Integer lineNumber = parseIntSafe(lineNumberString);

            if (lineNumber != null) {
                writer.name("lineNumber").value(lineNumber);
            }
            fragment = fragment.substring(0, lineNumberIndex);
        }

        writer.name("file").value(fragment);
        writer.endObject();
    }

    private void serialiseHermesFrame(JsonStream writer, String frame) throws IOException {
        // expected format is as follows:
        //   release
        //     "at $method (address at $filename:$lineNumber:$columnNumber)"
        //   dev
        //     "at $method ($filename:$lineNumber:$columnNumber)"

        int srcInfoStart = Math.max(frame.lastIndexOf(" "), frame.lastIndexOf("("));
        int srcInfoEnd = frame.lastIndexOf(")");
        boolean hasSrcInfo = srcInfoStart > -1 && srcInfoStart < srcInfoEnd;

        int methodStart = "at ".length();
        int methodEnd = frame.indexOf(" (");
        boolean hasMethodInfo = methodStart < methodEnd;

        // serialise srcInfo
        if (hasSrcInfo || hasMethodInfo) {
            writer.beginObject();
            writer.name("method").value(frame.substring(methodStart, methodEnd));
            if (hasSrcInfo) {
                String srcInfo = frame.substring(srcInfoStart + 1, srcInfoEnd);
                // matches `:123:34` at the end of a string such as "index.android.bundle:123:34"
                // so that we can extract just the filename portion "index.android.bundle"
                String lineColRe = ":\\d+:\\d+$";
                String file = srcInfo.replaceFirst(lineColRe, "");

                writer.name("file").value(file);

                String[] chunks = srcInfo.split(":");
                if (chunks.length >= 2) {
                    Integer lineNumber = parseIntSafe(chunks[chunks.length - 2]);
                    Integer columnNumber = parseIntSafe(chunks[chunks.length - 1]);

                    if (lineNumber != null) {
                        writer.name("lineNumber").value(lineNumber);
                    }
                    if (columnNumber != null) {
                        writer.name("columnNumber").value(columnNumber);
                    }
                }
            }
            writer.endObject();
        }
    }

    private Integer parseIntSafe(String maybeInt) {
        try {
            return Integer.parseInt(maybeInt);
        } catch (NumberFormatException exc) {
            BugsnagReactNative.logger.info(
                String.format("Expected an integer, got: '%s'", maybeInt));
            return null;
        }
    }
}
