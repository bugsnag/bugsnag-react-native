package com.bugsnag;

import com.bugsnag.android.JsonStream;

import org.junit.Before;
import org.junit.Test;

import java.io.BufferedWriter;
import java.io.StringWriter;
import java.io.Writer;

import static org.junit.Assert.*;

public class JavaScriptExceptionTest {
    
    private JsonStream stream;
    
    @Before
    public void setup() {
        Writer writer = new StringWriter();
        stream = new JsonStream(new BufferedWriter(writer));
    }

    @Test
    public void parseHermesException() throws Exception {
        String stacktrace = "Error: oh" +
            "at anonymous (address at index.android.bundle:1:17468)" +
            "at v (address at index.android.bundle:1:11340)" +
            "at d (address at index.android.bundle:1:10990)" +
            "at o (address at index.android.bundle:1:10659)" +
            "at global (address at index.android.bundle:1:10391)";

        JavaScriptException exc = new JavaScriptException("TypeError", "undefined is not a function", stacktrace);
        exc.toStream(stream);

        // TODO assert exc here
        fail();
    }
    
    @Test
    public void parseStandardException() throws Exception {
        String stacktrace = "index.android.bundle:6:164" +
        "v@index.android.bundle:2:1474" +
        "d@index.android.bundle:2:876" +
        "global code@index.android.bundle:352:4";
            
        JavaScriptException exc = new JavaScriptException("TypeError", "undefined is not a function", stacktrace);
        exc.toStream(stream);

        // TODO assert exc here
        fail();
    }

}