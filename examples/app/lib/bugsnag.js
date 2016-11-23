//-------------------------------------------------------------------------------------------------
// Create a singleton instance of the bugsnag client so we don't have to duplicate our configuration
// anywhere.
//-------------------------------------------------------------------------------------------------
// https://docs.bugsnag.com/platforms/react-native/#basic-configuration
import { Client } from 'bugsnag-react-native';
const client = new Client('API_KEY_GOES_HERE');
//-------------------------------------------------------------------------------------------------
export default client;
