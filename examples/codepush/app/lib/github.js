import bugsnag from 'lib/bugsnag';
// -----------------------------------------------------------------------------------------------
// Simple library for fetching information from the github rest API
// -----------------------------------------------------------------------------------------------

const API_ROOT = "https://api.github.com";
const headers = {
// If you hit API rate limiting, generate a personal access token (https://github.com/settings/tokens)
// and add it to the following line uncomment the following line

//   'Authorization': 'token MY_TOKEN_HERE',
};

// Standard response parser. Will return json promise if request is successful.
// Otherwise will return rejected promise
const responseHandler = (response) => {
  if (response.ok) {
    return response.json();
  }
  // if the response is not ok, reject the promise with the error.message
  return response
    .json()
    .then((error) => {
      // send rejected promises to bugsnag
      // https://docs.bugsnag.com/platforms/react-native/#reporting-promise-rejections
      bugsnag.notify(new Error(error.message));
      return Promise.reject(error.message);
    });
}

const performFetch = endpoint => {
  // leave a breadcrumb for bugsnag
  // https://docs.bugsnag.com/platforms/react-native/#logging-breadcrumbs
  bugsnag.leaveBreadcrumb('Github Request', { type: 'network', endpoint });
  // perform the fetch
  return fetch(`${API_ROOT}/${endpoint}?`, {headers}).then(responseHandler);
}

// -----------------------------------------------------------------------------------------------
// Public API
// -----------------------------------------------------------------------------------------------
const getRepos = (org) => performFetch(`orgs/${org}/repos`);
const getUser = (username) => performFetch(`users/${username}`);

export default {
  getRepos,
  getUser,
};
// -----------------------------------------------------------------------------------------------
