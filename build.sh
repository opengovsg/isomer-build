#!/bin/bash 

#####################################################################
# Override customHttp.yml with centrally-hosted customHttp.yml file #
#####################################################################
curl https://raw.githubusercontent.com/opengovsg/isomer-build/amplify-disable-next-gen-check/overrides/customHttp.yml -o customHttp.yml


#####################################################
# Delete custom plugins from _plugins folder if any #
#####################################################
rm -rf _plugins

##################################################
# Check that Gemfile has not been tampered with. #
# The Gemfile can either reference isomer-jekyll #
# or github-pages                                #
##################################################
curl https://raw.githubusercontent.com/opengovsg/isomer-build/master/overrides/Gemfile-github-pages -o Gemfile-github-pages
curl https://raw.githubusercontent.com/opengovsg/isomer-build/master/overrides/Gemfile-isomer-jekyll -o Gemfile-isomer-jekyll
diff_line_count_github_pages_gemfile=$(diff --ignore-space-change Gemfile Gemfile-github-pages | wc -l)
diff_line_count_isomer_jekyll_gemfile=$(diff --ignore-space-change Gemfile Gemfile-isomer-jekyll | wc -l)
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

#################################
# Install git lfs, if available #
#################################
if git lfs install; then
  echo "git lfs installed"
else
  echo "git lfs not installed"
fi

# Amplify build
bundle exec jekyll build --config _config.yml",$var"
