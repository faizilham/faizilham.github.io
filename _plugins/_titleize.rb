require 'liquid'
require 'uri'

# Title case
module Titleize
  def titleize(words)
    return words.split(/[_\- ]+/).map(&:capitalize).join(' ')
  end
end

Liquid::Template.register_filter(Titleize)
