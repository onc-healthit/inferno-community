from ruby:2.5

# Install gems
ENV APP_HOME /server-build
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/
RUN bundle install
