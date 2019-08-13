package com.bugsnag;

import com.bugsnag.android.JsonStream;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.junit.Test;

import java.io.IOException;
import java.io.StringWriter;

import static org.junit.Assert.assertEquals;

public class JavaScriptExceptionTest {

    @Test
    public void parseHermesException() throws Exception {
        String stacktrace = "Error: oh\n" +
                "at anonymous (address at index.android.bundle:6:17468)\n" +
                "at v (address at index.android.bundle:6:164)\n" +
                "at d (address at index.android.bundle:2:1474)\n" +
                "at o (address at index.android.bundle:1:512)\n" +
                "at global (address at index.android.bundle:4:352)\n";

        JavaScriptException exc = new JavaScriptException("TypeError", "undefined is not a function", stacktrace);
        JSONObject json = streamToJson(exc);
        validateExcJson(json);
        validateStacktraceJson(json);
    }

    @Test
    public void parseStandardException() throws Exception {
        String stacktrace = "index.android.bundle:6:164\n" +
                "v@index.android.bundle:2:1474\n" +
                "d@index.android.bundle:2:876\n" +
                "o@index.android.bundle:1:512\n" +
                "global code@index.android.bundle:352:4\n";

        JavaScriptException exc = new JavaScriptException("TypeError", "undefined is not a function", stacktrace);
        JSONObject json = streamToJson(exc);
        validateExcJson(json);
        validateStacktraceJson(json);
    }

    private void validateExcJson(JSONObject json) throws JSONException {
        assertEquals("TypeError", json.getString("errorClass"));
        assertEquals("undefined is not a function", json.getString("message"));
        assertEquals("browserjs", json.getString("type"));
    }

    private void validateStacktraceJson(JSONObject json) throws JSONException {
        // validate stacktrace
        JSONArray trace = json.getJSONArray("stacktrace");
        assertEquals(5, trace.length());

        // frame 0
        JSONObject frame0 = trace.getJSONObject(0);
        assertEquals(164, frame0.get("columnNumber"));
        assertEquals(6, frame0.get("lineNumber"));
        assertEquals("index.android.bundle", frame0.get("file"));

        // frame 1
        JSONObject frame1 = trace.getJSONObject(1);
        assertEquals(1474, frame1.get("columnNumber"));
        assertEquals(2, frame1.get("lineNumber"));
        assertEquals("v", frame1.get("method"));
        assertEquals("index.android.bundle", frame1.get("file"));

        // frame 2
        JSONObject frame2 = trace.getJSONObject(2);
        assertEquals(876, frame2.get("columnNumber"));
        assertEquals(2, frame2.get("lineNumber"));
        assertEquals("d", frame2.get("method"));
        assertEquals("index.android.bundle", frame2.get("file"));

        // frame 3
        JSONObject frame3 = trace.getJSONObject(3);
        assertEquals(512, frame3.get("columnNumber"));
        assertEquals(1, frame3.get("lineNumber"));
        assertEquals("o", frame3.get("method"));
        assertEquals("index.android.bundle", frame3.get("file"));

        // frame 4
        JSONObject frame4 = trace.getJSONObject(4);
        assertEquals(4, frame4.get("columnNumber"));
        assertEquals(352, frame4.get("lineNumber"));
        assertEquals("global code", frame4.get("method"));
        assertEquals("index.android.bundle", frame4.get("file"));
    }

    private JSONObject streamToJson(
            JsonStream.Streamable streamable) throws IOException, JSONException {
        StringWriter writer = new StringWriter();
        JsonStream jsonStream = new JsonStream(writer);
        streamable.toStream(jsonStream);
        return new JSONObject(writer.toString());
    }

}