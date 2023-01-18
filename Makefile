.PHONY: all clean docker-images docker-image-latest docker-push docker-run-latest dump-env

IMAGE_NAME ?= "iuridiniz/haproxy"
ENVS_DIR ?= envs
ENVIRONMENTS ?= $(shell ls -1 $(ENVS_DIR)/latest $(ENVS_DIR)/[1-9]*)

all: docker-images

clean:
	# nothing to clean

docker-images: 
	IMAGE_NAME=$(IMAGE_NAME) ENVS_DIR=$(ENVS_DIR) ENVIRONMENTS="$(ENVIRONMENTS)" ./scripts/build.sh
	docker image ls $(IMAGE_NAME)

docker-push: docker-images
	for env in $(ENVIRONMENTS); do \
		docker push $(IMAGE_NAME):$$(basename $$env); \
	done

docker-image-latest:
	make docker-images ENVIRONMENTS="$(ENVS_DIR)/latest" 

docker-run-latest: docker-image-latest
	docker run -it --rm $(IMAGE_NAME):latest /bin/bash

dump-env:
	@echo IMAGE_NAME=\"$(IMAGE_NAME)\"
	@echo ENVS_DIR=\"$(ENVS_DIR)\"
	@echo ENVIRONMENTS=\"$(ENVIRONMENTS)\"
