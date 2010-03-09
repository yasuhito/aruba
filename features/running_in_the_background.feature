Feature: Running in the background
  In order to test programs that need interaction
  Developers should be able to run programs in the background

  Scenario: Send stuff to STDIN
    When I run "ruby -e 'puts \"Your name: \"; puts STDIN.readline'" as child "yourname"
    And I type "hello\n" to child "yourname"
    Then I should see "hello" from child "yourname"

  Scenario: Don't send stuff to STDIN
    When I run "ruby -e 'puts \"Your name: \"; puts STDIN.readline'" as child "blocking"
    And I send signal "TERM" to child "blocking"
    Then the child "blocking" should not be running
