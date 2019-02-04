const fs = require('fs');
const glob = require('glob');
const { upload } = require('bugsnag-sourcemaps');
const path = require('path');

// NOTE: this script assumes RN packager built a js "unbundle" bundle into a local `./tmp` directory

const promisify = fn => new Promise((res, rej) => {
  const done = (err, val) => (err ? rej(err) : res(val));
  fn(done);
});

const getFile = fpath => promisify(cb => fs.readFile(fpath, 'utf8', cb));
const writeFile = (fpath, src) => promisify(cb => fs.writeFile(fpath, src, cb));
const pupload = o => promisify(cb => upload(o, cb));
const defer = ms => new Promise(r => setTimeout(r, ms));

const apiKey = '035297f9b1a99e22931db10049fec7ac'; // omitted

const root = path.resolve('') + '/';
const jsRoot = path.join(root, './tmp/');
const appVersion = '1'; // this value was hard coded for testing

// magic offset number. this might change with each RN version. Script was run with RN 0.41
// const offset = 11; 


function cleanPath(str) {
  return str.replace(root, '~/');
}

// the sourcemaps have local paths in them that make the stack traces really long
// and harder to read. This method will just recursively trim the paths so that they are
// relative to the repo root.
function cleanPaths(map) {
  const result = Object.assign({}, map);
  if (Array.isArray(map.sections)) {
    result.sections = map.sections.map(cleanPaths);
  }
  if (Array.isArray(map.sources)) {
    result.sources = map.sources.map(cleanPath);
  }
  return result;
}

function uploadSourceMap(map, fname, mapPath, minJsPath) {
  const fullMap = Object.assign({}, cleanPaths(map), {
    file: fname,
  });
  return writeFile(mapPath, JSON.stringify(fullMap))
    .then(() => console.log(`Uploading ${fname}...`))
    // .then(() => {
    //   return pupload({
    //     apiKey: apiKey,
    //     appVersion: appVersion,
    //     minifiedUrl: fname,
    //     sourceMap: mapPath,
    //     minifiedFile: minJsPath,
    //     overwrite: true,
    //   });
    // })
    .then(() => console.log(`Uploading ${fname}... DONE`))
    // added this timeout to avoid bugsnag rate limiting
    // .then(() => defer(1500));
}

getFile(path.join(jsRoot, 'android-release.bundle.map'))
  .then(src => JSON.parse(src))
  .then(map => {
    let promise = Promise.resolve();
    let sections = map.sections;
    let offsets = map.x_facebook_offsets;

    console.log(sections.map((section, i) => {
      if (!sections[offsets[i] - 1]) return {}
      return {
        offset: offsets[i] - 1,
        map: sections[offsets[i] - 1],
        sourcesContent: sections[offsets[i] - 1].map.sourcesContent.slice(0, 1000),
        name: `${offsets[i] - 1}.js.map`,
        originalJsFile: sections[offsets[i] - 1].map.sources.join(','),
        bundledJs: fs.readFileSync(path.join(jsRoot, `js-modules/${offsets[i] - 1}.js`), 'utf8').slice(0, 1000)
      }
    }))
    return promise;
  })
  .then(() => console.log('DONE!!!!'))
  .catch(err => console.error(err));


  // let sourcemapIndex = offsets[i];
  // if (sourcemapIndex !== null) {
  //   // promise = promise.then(() => uploadSourceMap(
  //   //   sections[sourcemapIndex - 11].map,
  //   //   `${i}.js`,
  //   //   path.resolve(path.join(jsRoot, 'js-modules', `${i}.js.map`)),
  //   //   path.resolve(path.join(jsRoot, 'js-modules', `${i}.js`))
  //   // ));
  // }