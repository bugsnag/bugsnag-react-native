const config = {
    transformer: {
      getTransformOptions: () => {
        return {
          transform: { inlineRequires: true },
        };
      },
    },
    projectRoot: "/Users/jamielynch/repos/bugsnag-react-native/examples/plain",
  };
  
module.exports = config;