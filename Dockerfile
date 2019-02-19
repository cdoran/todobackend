### Test stage ###
# run: docker run -it --rm todobackend-test
FROM alpine AS test
LABEL application=todobackend

# Install basic utilities
RUN apk add --no-cache bash git

# Install build dependencies
RUN apk add --no-cache gcc python3-dev libffi-dev musl-dev linux-headers mariadb-dev
RUN pip3 install wheel

# Copy requirements
COPY /src/requirements* /build/
WORKDIR /build

# Build and install test requirements
RUN pip3 wheel -r requirements_test.txt --no-cache-dir --no-input
RUN pip3 install -r requirements_test.txt -f /build --no-index --no-cache-dir

# Copy source code
COPY /src /app
WORKDIR /app

# Test entrypoint, this is where settings_test.py is set
CMD ["python3", "manage.py", "test", "--noinput", "--settings=todobackend.settings_test"]


### Release Stage ###
# run: docker run -it --rm -p 8000:8000 todobackend-release uwsgi --http=0.0.0.0:8000 --module=todobackend.wsgi --master
FROM alpine
LABEL application=todobackend

# Install operating system dependencies
RUN apk add --no-cache python3 mariadb-client bash curl bats jq

# Create a group and user for the app
RUN addgroup -g 1000 app && adduser -u 1000 -G app -D app

# Copy and install application from source and pre-built dependencies
COPY --from=test --chown=app:app /build /build
COPY --from=test --chown=app:app /app /app
RUN pip3 install -r /build/requirements.txt -f /build --no-index --no-cache-dir
RUN rm -rf /build

# Create public volume for static content
RUN mkdir /public
RUN chown app:app /public
VOLUME /public

# Set working directory and app user
WORKDIR /app
USER app
