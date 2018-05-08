FROM ruby:2.5

# Install gems into a temporary directory
COPY Gemfile* ./
RUN bundle install

# Expose the port
EXPOSE 4567
