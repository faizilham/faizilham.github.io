task :default do
  puts "Running CI tasks..."

  sh("JEKYLL_ENV=production bundle exec jekyll doctor")
  sh("JEKYLL_ENV=production bundle exec jekyll build")
  sh("touch _site/.nojekyll")

  puts "Jekyll successfully built"
end

task :precommit do
  sh("bundle exec jekyll doctor")
end
