task :default do
  sh("sh ./script/build.sh")
end

task :deploy do
  sh("sh ./script/deploy.sh")
end


task :precommit do
  sh("bundle exec jekyll doctor")
end
