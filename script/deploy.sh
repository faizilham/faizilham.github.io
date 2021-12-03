#!/bin/bash

DATE=$(date +"%Y-%m-%d %T")

cd _site
git init
git add --all
git commit -m "Deployment $DATE"
git remote add origin git@github.com:faizilham/faizilham.github.io.git
git push -f origin master

echo "Site is successfully deployed"
