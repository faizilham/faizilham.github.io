task :default do
  puts "Running CI tasks..."

  sh("JEKYLL_ENV=production bundle exec jekyll build")
  sh("touch _site/.nojekyll")

  test_commit

  puts "Jekyll successfully built"
end

def test_commit
  $("git commit --allow-empty -m \"[skip ci] test empty $(git rev-parse HEAD)\"")
  $("git push origin source")
end
