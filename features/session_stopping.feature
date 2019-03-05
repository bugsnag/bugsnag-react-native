Feature: Stopping and resuming sessions

Scenario Outline: When a session is stopped the error has no session information
    When I launch an <platform> app with "StoppedSessionScenario"
    Then I should receive 2 requests
    And the request 0 is valid for the session tracking API
    And the request 1 is valid for the error reporting API
    And the payload field "events.0.session" is null for request 1

    Examples:
    | platform |
    | Android  |
    | iOS      |

Scenario Outline: When a session is resumed the error uses the previous session
    When I launch an <platform> app with "ResumedSessionScenario"
    Then I should receive 2 requests
    And the request 0 is valid for the session tracking API
    And the request 1 is valid for the error reporting API
    And the payload field "events.0.session.events.handled" equals 1 for request 1
    And the payload field "events.0.session.events.unhandled" equals 0 for request 1

    Examples:
    | platform |
    | Android  |
    | iOS      |
