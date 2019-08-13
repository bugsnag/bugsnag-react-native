package com.bugsnag;

import com.bugsnag.android.JsonStream;

import java.io.IOException;

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

    @Override
    public void toStream(JsonStream writer) throws IOException {
        writer.beginObject();
        writer.name("errorClass").value(name);
        writer.name("message").value(getLocalizedMessage());
        writer.name("type").value(EXCEPTION_TYPE);

        writer.name("stacktrace");
        writer.beginArray();

        boolean usesHermes = true;
        // TODO should pass in global.HermesInternal from the JS layer in init

        for (String frame : rawStacktrace.split("\\n")) {
            if (usesHermes) {
                serialiseHermesFrame(writer, frame);
            } else {
                serialiseJsCoreFrame(writer, frame);
            }
        }

        writer.endArray();
        writer.endObject();
    }

    private void serialiseJsCoreFrame(JsonStream writer, String frame) throws IOException {
        // expected format is as follows:
        // "$method@$filename:$lineNumber:$columnNumber\n"

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
        // "at $method (address at $filename:$lineNumber:$columnNumber)\n"

        int srcInfoStart = frame.lastIndexOf(" ");
        int srcInfoEnd = frame.lastIndexOf(")");
        boolean hasSrcInfo = srcInfoStart > -1 && srcInfoStart < srcInfoEnd;

        int methodStart = "at ".length();
        int methodEnd = frame.indexOf(" (address");
        boolean hasMethodInfo = methodStart < methodEnd;

        // serialise srcInfo
        if (hasSrcInfo || hasMethodInfo) {
            writer.beginObject();
            writer.name("method").value(frame.substring(methodStart, methodEnd));

            if (hasSrcInfo) {
                String srcInfo = frame.substring(srcInfoStart, srcInfoEnd);
                String[] data = srcInfo.split(":");

                if (data.length == 3) {
                    writer.name("file").value(data[0].trim());

                    Integer lineNumber = parseIntSafe(data[1]);
                    Integer columnNumber = parseIntSafe(data[2]);

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

    private Integer parseIntSafe(String n) {
        try {
            return Integer.parseInt(n);
        } catch (NumberFormatException exc) {
            BugsnagReactNative.logger.info(String.format("Expected an integer, got: '%s'", n));
            return null;
        }
    }
}
