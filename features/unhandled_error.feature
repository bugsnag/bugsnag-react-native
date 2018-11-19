Feature: Reporting unhandled errors on iOS

    Scenario Outline: Thrown exception
        When I launch an <platform> app which has an uncaught exception
        Then I should receive a request
        And the request is a valid for the error reporting API
        And the exception "errorClass" equals "TypeError"

        Examples:
        | platform |
        | iOS      |
        | Android  |

    Scenario Outline: Unhandled promise rejection
        When I launch an <platform> app which has an unhandled promise rejection
        Then I should receive a request
        And the request is a valid for the error reporting API
        And the exception "errorClass" equals "SyntaxError"

        Examples:
        | platform |
        | iOS      |
        | Android  |
