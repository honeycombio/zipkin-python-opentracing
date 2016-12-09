.PHONY: build thrift lint docs dist inc-version publish sample-app \
	test test-util test-runtime test-opentracing \
	default

default: test

build:
	echo "Nothing to build"

check-virtual-env:
	@echo virtual-env: $${VIRTUAL_ENV?"Please run in virtual-env"}

bootstrap: check-virtual-env
	pip install -r requirements.txt
	pip install -r requirements-test.txt
	python setup.py develop

lint:
	pylint -r n --disable=invalid-name,global-statement,bare-except \
		zipkin_ot/tracer.py zipkin_ot/constants.py zipkin_ot/recorder.py

docs:
	cd docs && make html

dist: build docs inc-version
	mkdir -p dist
	rm -rf dist
	python setup.py sdist      # source distribution
	python setup.py bdist_wheel

# TODO: There's inelegant dependency on Node.js here
inc-version: scripts/node_modules
	node scripts/inc_version.js
	git tag `cat VERSION`

scripts/node_modules:
	cd scripts && npm update

publish: dist
	@if [ $(shell git symbolic-ref --short -q HEAD) = "master" ]; then exit 0; else \
	echo "Current git branch does not appear to be 'master'. Refusing to publish."; exit 1; \
	fi
	git add VERSION zipkin_ot/version.py setup.py
	git commit -m "Updating Version to `cat VERSION`"
	git push
	git push --tags
	twine upload dist/*

example: build
	python examples/trivial/main.py

test: build
	tox

#thrift:
	#thrift -r -gen py -out zipkin_ot/ zipkin_ot/thrift/zipkinCore.thrift
