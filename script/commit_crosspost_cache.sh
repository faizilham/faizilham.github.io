#!/bin/sh

if status=$(git status --porcelain | grep .jekyll-crosspost_to_medium ) && [ -n "$status" ]; then
    git config user.name "Deployment Bot (from Travis CI)"
    git config user.email "deploy@travis-ci.org"

    git add .jekyll-crosspost_to_medium/medium_crossposted.yml
    git commit -m "[skip ci] update crosspost cache for $(git rev-parse HEAD)"

    git remote add production https://${GITHUB_TOKEN}@github.com/faizilham/faizilham.github.io.git
    git push production $(git rev-parse HEAD):source
fi
