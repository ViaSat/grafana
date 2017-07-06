all: deps build

# Dependency imports rely on the absolute path $(GOPATH)/src/github.com/grafana/grafana
# Recommend using a symlink in $(GOPATH)/src/github.com/grafana to point to your specific grafana source tree
# Has to be an explicit dependency since some targets such as run, push and update-from-upstream shouldn't do this check
.PHONY: dircheck
dircheck:
ifneq ($(PWD), $(GOPATH)/src/github.com/grafana/grafana)
	$(error "Can't build here - you are not in $(GOPATH)/src/github.com/grafana/grafana!")
endif

deps-go: dircheck
	go run build.go setup

deps-js:
	yarn install --pure-lockfile --no-progress

deps: deps-js

build-go: dircheck
	go run build.go build

build-js:
	npm run build

build: build-go build-js

test-go: dircheck
	go test -v ./pkg/...

test-js:
	npm test

test: test-go test-js

run:
	./bin/grafana-server

package: dircheck
	go run build.go package

.PHONY: push
push:
	./artifactory_push.sh

# Fork support - attaches the master GitHub repo as a remote called 'upstream'
.PHONY: attach-upstream
attach-upstream:
	git remote -v | grep upstream && echo "upstream fork already attached" || git remote add upstream https://github.com/grafana/grafana.git

# Fork support - after you fork and clone, use this to update your fork from the parent project
# automatically attaches the upstream remote if not already present
.PHONY: update-from-upstream
update-from-upstream: attach-upstream
	git fetch upstream
	git checkout master
	git merge upstream/master
