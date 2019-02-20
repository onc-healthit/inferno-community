FROM ruby:2.5

# Install gems into a temporary directory
COPY Gemfile* ./
RUN bundle install

# Expose the port
EXPOSE 4567

RUN apt-get update
RUN apt-get install -y libnss3 fonts-liberation libappindicator3-1 libasound2 libatk-bridge2.0-0 libgtk-3-0 libnspr4 libx11-xcb1 libxss1 libxtst6 lsb-release xdg-utils

# Install Chrome
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN dpkg -i google-chrome-stable_current_amd64.deb; apt-get -fy install

ADD ./chromedriver /usr/local/bin
