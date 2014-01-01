#!/bin/bash

# Hardcode the new gtest version.
GTEST_ROOT=$HOME/gtest-1.7.0

# Get the directory of the script.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PACKAGE="--all"
DEPENDENCIES=""

# Download / update dependencies.
for i in "$@"
do
case $i in
    -p=*|--packages=*)
    PACKAGES="${i#*=}"
    ;;
    -d=*|--dependencies=*)
    DEPENDENCIES="${i#*=}"
    ;;
    *)
       echo "Usage: run_build [{-d|--dependencies}=dependency.git] [{-p|--packages}=packages]"
    ;;
esac
done
echo PACKAGES = "${PACKAGES}"
echo DEPENDENCIES = "${DEPENDENCIES}"

# Prepare cppcheck ignore list. We want to skip dependencies.
CPPCHECK_PARAMS=". src --xml --enable=all -j8 -i build "

mkdir -p $WORKSPACE/src && cd $WORKSPACE/src
for dependencies in ${DEPENDENCIES}
do
    foldername_w_ext=${dependencies##*/}
    foldername=${foldername_w_ext%.*}
    if [ -d $foldername ]; then
      echo Folder "$foldername" exists, running git pull on "$dependencies"
      cd "$foldername" && git pull && cd ..
    else
      echo Folder "$foldername" does not exists, running git clone "$dependencies"
      git clone "$dependencies" --recursive
    fi  
    CPPCHECK_PARAMS="$CPPCHECK_PARAMS -i $foldername -isrc/$foldername "
done
cd $WORKSPACE

#Now run the build.
if $DIR/run_build_catkin_or_rosbuild ${PACKAGES}; then
  echo "Running cppcheck $CPPCHECK_PARAMS ..."
  # Run cppcheck excluding dependencies.
  cd $WORKSPACE
  rm -f cppcheck-result.xml
  cppcheck $CPPCHECK_PARAMS 2> cppcheck-result.xml || true
else
 exit 1
fi


