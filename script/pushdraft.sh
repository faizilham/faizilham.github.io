#!/bin/bash

git checkout draft
git push origin draft
git checkout main
git merge draft
git push origin main
git checkout draft
