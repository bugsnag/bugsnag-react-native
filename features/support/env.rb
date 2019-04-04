# Any 'run once' setup should go here as this file is evaluated
# when the environment loads.
# Any helper functions added here will be available in step
# definitions
version = JSON.load(File.read('package.json'))["version"]
run_required_commands([
  ['features/scripts/launch_ios_sim.sh'],
  ['features/scripts/pack.sh'],
])

Dir.chdir('features/fixtures/sampler') do
  run_required_commands([
    ["npm install -g react-native-cli"],
    ["npm install"],
    ["npm install ../../../bugsnag-react-native-#{version}.tgz --no-package-lock --no-save"]
  ])
end

def launch_packager
  run_script('features/scripts/launch_packager.sh')
end

def set_envfile(envfile)
  Dir.chdir('features/fixtures/sampler') do
    begin
      FileUtils.rm('.env')
      FileUtils.cp("scenario_envs/#{envfile}.env", '.env')
    rescue => exception
      exit("envfile could not be set:", exception)
    end

  end
end

# Scenario hooks
Before do
  Dir.chdir('features/fixtures/sampler') do
    begin
      FileUtils.cp('scenario_envs/default.env', '.env')
    rescue => exception
      exit("envfile could not be set:", exception)
    end
  end
end

After do
  Dir.chdir('features/fixtures/sampler') do
    begin
      FileUtils.rm('.env')
    rescue => exception
      exit("envfile could not be set:", exception)
    end
  end
end

# Runs just before the test suite is terminated
at_exit do
  Dir.chdir('features/fixtures/sampler') do
    run_required_commands([
      ["rm -rf features/fixtures/sampler/node_modules/bugsnag-react-native"],
      ["pkill Simulator"]
    ])
  end
end
