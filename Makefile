all: deps build

deps-go:
	go run build.go setup

deps-js:
	yarn install --pure-lockfile --no-progress

deps: deps-go deps-js

build-go:
	go run build.go build

build-js:
	npm run build

build: build-go build-js

test-go:
	go test -v ./pkg/...

test-js:
	npm test

test: test-go test-js

run:
	./bin/grafana-server

package:
	go run build.go package

push:
	artifactory_push.sh

attach-upstream:
	git remote -v | grep upstream && echo "upstream fork already attached" || git remote add upstream https://github.com/grafana/grafana.git

update-from-upstream: attach-upstream
	git fetch upstream
	git checkout master
	git merge upstream/master
