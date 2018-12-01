task :default do
  puts "Running CI tasks..."

  sh("JEKYLL_ENV=production bundle exec jekyll build")
  sh("touch _site/.nojekyll")
  sh("sh script/commit_crosspost_cache.sh")

  puts "Jekyll successfully built"
end
