
# Enable livereload
activate :livereload
# Enable pretty URLs
activate :directory_indexes
# Set CSS directory
set :css_dir, 'stylesheets'
# Set JavaScripts directory
set :js_dir, 'javascripts'
# Set images directory
set :images_dir, 'images'
# Set build directory
set :build_dir, 'public'
# Build-specific configuration
configure :build do
  # Minify Stylesheets
  activate :minify_css
  # Minify JavaScripts
  activate :minify_javascript
  # Enable cache buster
  activate :asset_hash
  # GZIP time
  # activate :gzip
end

activate :deploy do |deploy|
  deploy.method = :git
end
