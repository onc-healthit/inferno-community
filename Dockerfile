FROM ruby:2.5

# Install gems into a temporary directory
COPY Gemfile* ./
RUN bundle install

# Set up unicorn (BUT the config will come from the mounted volume)
RUN gem install unicorn
RUN mkdir /var/unicorn && mkdir /var/unicorn/pids && mkdir /var/unicorn/log

# Expose the port set up in unicorn.rb
EXPOSE 8080
