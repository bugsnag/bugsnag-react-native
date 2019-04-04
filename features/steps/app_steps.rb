def launch_crashy_app(os, event)
  if (os == "android")
    emulator = ENV['ANDROID_EMULATOR']
    assert(emulator && emulator.length > 0, "ANDROID_EMULATOR variable is not set")
    assert(ENV['ANDROID_HOME'] && ENV['ANDROID_HOME'].length > 0, "ANDROID_HOME variable is not set")
    step("I start Android emulator \"#{emulator}\"")
  end
  step("I set environment variable \"EVENT_TYPE\" to \"#{event}\"")
  run_required_commands([["features/scripts/launch_#{os}_app_crash.sh"]])
end

When(/^I launch an (\w+) app with "(\w+)"$/) do |os, event_type|
  launch_crashy_app(os.downcase, event_type)
end
When(/^I launch an (\w+) app which has an uncaught exception$/) do |os|
  launch_crashy_app(os.downcase, "uncaughtException")
end
When(/^I launch an (\w+) app which has an unhandled promise rejection$/) do |os|
  launch_crashy_app(os.downcase, "unhandledRejection")
end
When(/^I launch an (\w+) app which has a syntax error$/) do |os|
  launch_crashy_app(os.downcase, "syntaxError")
end

When("I set the envfile to {string}") do |envfile|
  set_envfile(envfile)
end
