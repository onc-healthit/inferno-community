FROM ruby:2.5

# Install gems into a temporary directory
COPY Gemfile* *.gemspec .git ./
COPY ./lib/version.rb ./lib/
RUN bundle install

# Expose the port
EXPOSE 4567
