#!/bin/bash 

#################################################################
# Override netlify.toml with centrally-hosted netlify.toml file #
#################################################################
curl https://raw.githubusercontent.com/opengovsg/isomer-build/test/overrides/netlify.toml -o /opt/build/repo/netlify.toml

###################################################################
# Obtain config override file to enforce plugins and remote theme #
###################################################################
curl https://raw.githubusercontent.com/opengovsg/isomer-build/test/overrides/_config-override.yml -o /opt/build/repo/_config-override.yml
echo "Printing override file"
cat /opt/build/repo/_config-override.yml

#####################################################
# Delete custom plugins from _plugins folder if any #
#####################################################
rm -rf _plugins

#################################################
# Check that Gemfile has not been tampered with #
#################################################
curl https://raw.githubusercontent.com/opengovsg/isomer-build/test/overrides/Gemfile -o /opt/build/repo/Gemfile-template
diff_line_count_gemfile=$(diff --ignore-space-change /opt/build/repo/Gemfile /opt/build/repo/Gemfile-template | wc -l)

echo "Printing Gemfile"
cat /opt/build/repo/Gemfile
echo "Printing Template"
cat /opt/build/repo/Gemfile-template

if (( diff_line_count_gemfile > 0 )); then
  echo "Gemfile was tampered with"
  exit 1
fi

###############################################################
# Generate build script for Jekyll v4 collections structure   #
###############################################################
# search within all collections for collection.yml file
collections=$(find . -path ./_site -prune -false -o -name collection.yml -type f)
var=$(echo $collections | sed 's/ .\//,.\//g')

env='development'
while getopts "e:" opt; do
  case $opt in
    e) env=$OPTARG      ;;
    *) echo 'error' >&2
       exit 1
  esac
done

# netlify build
JEKYLL_ENV=$env jekyll build --config _config.yml",$var",/opt/build/repo/_config-override.yml
