#!/bin/bash
rm -rf _site
JEKYLL_ENV=production bundle exec jekyll doctor
JEKYLL_ENV=production bundle exec jekyll build
touch _site/.nojekyll
[ -f CNAME ] && cp CNAME _site/CNAME

echo "Site is successfully built"
