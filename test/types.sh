# /usr/bin/env bash

set -e

echo "cleaning up the file system state"
rm -rf test/tmp && mkdir -p test/tmp

echo "packaging the module"
# the last line of stdout in the npm pack command is the name of the .tgz it created
pkg_name=`npm pack . | tail -1`
echo $pkg_name

echo "unpackaging the module"
tar -xvf ${pkg_name} -C test/tmp

echo "running tslint"
./node_modules/.bin/tslint test/tmp/package/index.d.ts
echo "running tsc"
./node_modules/.bin/tsc --strict test/app.ts

echo "cleaning up"
rm -rf test/tmp
