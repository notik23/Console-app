
FROM ruby:3.3


RUN apt-get update && apt-get install -y sqlite3 libsqlite3-dev


WORKDIR /app
COPY . /app


RUN gem install bundler
RUN bundle install


CMD ["ruby", "App.rb"]
