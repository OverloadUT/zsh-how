.PHONY: all build test clean install

all: build test # build and run tests

build: # compile the project
	@echo "Building..."

test: # run the test suite
	@echo "Testing..."

lint: # run linters
	@echo "Linting..."

clean: # remove build artifacts
	@rm -rf build/ dist/

install: build # install locally
	@echo "Installing..."

docker-build: # build the Docker image
	@echo "Building Docker image..."

deploy: build test # deploy to production
	@echo "Deploying..."
