FROM ruby:2.5

# Install gems into a temporary directory
COPY Gemfile* ./
RUN gem install bundler && bundle install

# Expose the port
EXPOSE 4567
