@rails_aio_developer_chef

Feature: Rails AIO Developer (Chef Alpha) Server Template Test
  Rails AIO Developer (Chef Alpha) Server Template Test AND
  Rails AIO Demo (Chef Alpha) Server Template Test

Scenario: Rails AIO (Chef Alpha) Server Template Test

  Given A Rails AIO Developer Chef deployment
  #Then I should stop the servers
  Then I should launch all servers
  Then I should wait for the state of "all" servers to be "operational"
  Then I should run AIO rails demo application checks
  Then I should run log rotation checks

  #Then I should test reboot operations on the deployment
