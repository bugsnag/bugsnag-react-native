Feature: Detecting app not responding

Scenario: Test ANR detected with default timing
    When I set the envfile to "default-anr"
    And I launch an Android app with "TestANRLong"
    Then I should receive a request
    And the request is valid for the error reporting API
    And the exception "errorClass" equals "ANR"
    And the exception "message" equals "Application did not respond for at least 5000 ms"

Scenario: Test ANR not detected when disabled
    When I set the envfile to "default"
    And I launch an Android app with "TestANRLong"
    Then I should receive 0 requests

 Scenario: Test ANR not detected under response time
    When I set the envfile to "default-anr"
    And I launch an Android app with "TestANRShort"
    Then I should receive 0 requests

 Scenario: Test ANR wait time can be set to under default time
    When I set the envfile to "anr-short"
    And I launch an Android app with "TestANRShort"
    Then I should receive a request
    And the request is a valid for the error reporting API
    And the exception "errorClass" equals "ANR"
    And the exception "message" equals "Application did not respond for at least 3000 ms"

 Scenario: Test ANR wait time can be set to over default time
    When I set the envfile to "anr-long"
    And I launch an Android app with "TestANRLong"
    Then I should receive 0 requests
