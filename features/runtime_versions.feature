Feature: Runtime versions are included in all requests

    Scenario Outline: Uncaught exception contains runtime versions for Android
        When I launch an <platform> app which has an uncaught exception
        Then I should receive a request
        And the request is a valid for the error reporting API
        And the payload field "events.0.device.runtimeVersions.osBuild" is not null
        And the payload field "events.0.device.runtimeVersions.reactNative" is not null
        And the payload field "events.0.device.runtimeVersions.androidApiLevel" is not null

        Examples:
        | platform |
        | Android  |

    Scenario Outline: Session contains runtime versions for Android
        When I launch an <platform> app with "StoppedSessionScenario"
        Then I should receive 2 requests
        And the request 0 is valid for the session tracking API
        And the payload field "device.runtimeVersions.osBuild" is not null for request 0
        And the payload field "device.runtimeVersions.reactNative" is not null for request 0
        And the payload field "device.runtimeVersions.androidApiLevel" is not null for request 0

        Examples:
        | platform |
        | Android  |

    Scenario Outline: Session contains runtime versions from a native exception
        When I launch an <platform> app with "TriggerNativeError"
        Then I should receive a request
        And the request is a valid for the error reporting API
        And the payload field "events.0.device.runtimeVersions.osBuild" is not null
        And the payload field "events.0.device.runtimeVersions.reactNative" is not null
        And the payload field "events.0.device.runtimeVersions.androidApiLevel" is not null

        Examples:
        | platform |
        | Android  |