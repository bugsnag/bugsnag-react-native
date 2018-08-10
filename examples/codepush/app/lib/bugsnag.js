//-------------------------------------------------------------------------------------------------
// Create a singleton instance of the bugsnag client so we don't have to duplicate our configuration
// anywhere.
//-------------------------------------------------------------------------------------------------
// https://docs.bugsnag.com/platforms/react-native/#basic-configuration
import { Client, Configuration } from 'bugsnag-react-native';

const config = new Configuration('YOUR_API_KEY_HERE');
config.codeBundleId = '1.0.0-b12'
const client = new Client(config);
//-------------------------------------------------------------------------------------------------
export default client;
