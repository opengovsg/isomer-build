#!/bin/bash 

################################################
# Check repo is running on isomer v2 template. #
################################################
if ! grep -Fxq "remote_theme: isomerpages/isomerpages-template@next-gen" /opt/build/repo/_config.yml; then
  echo "$1 is not on isomerpages/isomerpages-template@next-gen"
  exit 1
fi

#################################################################
# Override netlify.toml with centrally-hosted netlify.toml file #
#################################################################
curl https://raw.githubusercontent.com/opengovsg/isomer-build/master/overrides/netlify.toml -o /opt/build/repo/netlify.toml

###################################################################
# Obtain config override file to enforce plugins and remote theme #
###################################################################
curl https://raw.githubusercontent.com/opengovsg/isomer-build/master/overrides/_config-override.yml -o /opt/build/repo/_config-override.yml

#####################################################
# Delete custom plugins from _plugins folder if any #
#####################################################
rm -rf _plugins

##################################################
# Check that Gemfile has not been tampered with. #
# The Gemfile can either reference isomer-jekyll #
# or github-pages                                #
##################################################
curl https://raw.githubusercontent.com/opengovsg/isomer-build/master/overrides/Gemfile-github-pages -o /opt/build/repo/Gemfile-github-pages
curl https://raw.githubusercontent.com/opengovsg/isomer-build/master/overrides/Gemfile-isomer-jekyll -o /opt/build/repo/Gemfile-isomer-jekyll
diff_line_count_github_pages_gemfile=$(diff --ignore-space-change /opt/build/repo/Gemfile /opt/build/repo/Gemfile-github-pages | wc -l)
diff_line_count_isomer_jekyll_gemfile=$(diff --ignore-space-change /opt/build/repo/Gemfile /opt/build/repo/Gemfile-isomer-jekyll | wc -l)
if (( diff_line_count_github_pages_gemfile > 0 && diff_line_count_isomer_jekyll_gemfile > 0 )); then
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