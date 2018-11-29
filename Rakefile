task :default do
  puts "Running CI tasks..."

  sh("JEKYLL_ENV=production bundle exec jekyll build")
  sh("touch _site/.nojekyll")

  test_commit

  puts "Jekyll successfully built"
end

def test_commit
  sh("git config user.name \"Deployment Bot (from Travis CI)\"")
  sh("git config user.email \"deploy@travis-ci.org\"")
  sh("git commit --allow-empty -m \"[skip ci] test empty $(git rev-parse HEAD)\"")
  sh("git remote add production https://${GITHUB_TOKEN}@github.com/faizilham/faizilham.github.io.git")
  sh("git push production $(git rev-parse HEAD):source")
end
