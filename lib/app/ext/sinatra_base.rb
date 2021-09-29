# frozen_string_literal: true

module Sinatra
  class Base
    # Brought in from `main` branch of Sinatra because it fixes a tree traveral
    # but is not yet available in a published gem.  Hopefully this will be
    # available in the version after v2.1.0.  This should be removed once it is
    # fixed in the latest published gem. Disabled rubocop so exact syntax from
    # original repo maintained.

    # See https://github.com/sinatra/sinatra/blob/2e980f3534b680fbd79d7ec39552b4afb7675d6c/lib/sinatra/base.rb#L1092-L1106

    # rubocop:disable all

    # Attempt to serve static files from public directory. Throws :halt when
    # a matching file is found, returns nil otherwise.
    def static!(options = {})
      return if (public_dir = settings.public_folder).nil?
      path = "#{public_dir}#{URI_INSTANCE.unescape(request.path_info)}"
      return unless valid_path?(path)

      path = File.expand_path(path)
      return unless path.start_with?(File.expand_path(public_dir) + '/')
      return unless File.file?(path)

      env['sinatra.static_file'] = path
      cache_control(*settings.static_cache_control) if settings.static_cache_control?
      send_file path, options.merge(:disposition => nil)
    end

    # rubocop:enable all
  end
end
