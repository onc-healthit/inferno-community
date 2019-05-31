# frozen_string_literal: true

# \ -s Thin -p 4567 -q
require './lib/app'

run Inferno::App.new
