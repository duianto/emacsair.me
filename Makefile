## Configuration #####################################################

DOMAIN         ?= emacsair.me
PUBLIC         ?= https://$(DOMAIN)
CFRONT_DIST    ?= E2AI8XS8J1IQIH
PUBLISH_BUCKET ?= s3://$(DOMAIN)
PREVIEW_BUCKET ?= s3://preview.$(DOMAIN)
S3_DOMAIN      ?= s3-website.eu-central-1.amazonaws.com
PUBLISH_S3_URL ?= http://$(DOMAIN).$(S3_DOMAIN)
PREVIEW_S3_URL ?= http://preview.$(DOMAIN).$(S3_DOMAIN)

SRC   = _site
SYNC  = # everything
PORT ?= 4000

## Usage #############################################################

help:
	$(info )
	$(info make build          - build using jekyll)
	$(info make serve          - run a local jekyll server)
	$(info make preview        - upload to preview site)
	$(info make publish        - upload to production site)
	$(info make clean          - remove build directory)
	$(info make ci-install     - install required tools)
	$(info make ci-version     - print version information)
	$(info )
	$(info Public:  $(PUBLIC))
	$(info Preview: $(PREVIEW_S3_URL))
	$(info Publish: $(PUBLISH_S3_URL))
	@echo
	@grep -e "^SRC" -e "^DST" -e "^SYNC" -e "^#NOT" Makefile
	@echo

## Targets ###########################################################

build:
	@jekyll build

serve:
	@jekyll serve --drafts -P $(PORT)

preview: clean build
	@if test $$(git symbolic-ref --short HEAD) = master; \
	then echo "Uploading to $(PREVIEW_BUCKET)..."; \
	else echo "ERROR: Only master can be previewed"; exit 1; fi
	@aws s3 sync $(SRC) $(PREVIEW_BUCKET)$(DST) --delete $(SYNC)

publish: clean build
	@if test $$(git symbolic-ref --short HEAD) = master; \
	then echo "Uploading to $(PUBLISH_BUCKET)..."; \
	else echo "ERROR: Only master can be published"; exit 1; fi
	@aws s3 sync $(SRC) $(PUBLISH_BUCKET)$(DST) --delete $(SYNC)
	@aws cloudfront create-invalidation \
	--distribution-id $(CFRONT_DIST) --paths "/*"

clean:
	@echo "Cleaning..."
	@rm -rf _site

ci-install:
	@apt-get -qq update
	@apt-get -qq install python-dev python-pip
	@gem install jekyll
	@pip install awscli

ci-version:
	@aws --version
	@jekyll --version
