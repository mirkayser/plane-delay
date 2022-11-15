all: usage

export USER = $(shell whoami)
export COMMIT = $(shell git rev-parse --short HEAD)
export REPO = $(shell terraform output --raw ecr_repository_name)

usage:
	@echo "Usage:"
	@echo " build: Build docker image."
	@echo " push: Push docker image to ECR."
	@echo " latest: Tag docker image as latest."
	@echo " deploy: Restart service on ECS to deploy latest image.."

build:
	docker build -t $(REPO):$(USER)-$(COMMIT) -f Dockerfile ./api/

push: build
	docker push $(REPO):$(USER)-$(COMMIT)

latest: push
	docker tag $(REPO):$(USER)-$(COMMIT) $(REPO):latest
	docker push $(REPO):latest

deploy: latest
	aws ecs update-service \
 		--force-new-deployment \
		--service $(shell terraform output -raw ecs_service_name) \
		--cluster $(shell terraform output -raw ecs_cluster_name) \
		--query "service.serviceArn"

public_ip:
	aws ecs list-tasks --cluster $(shell terraform output -raw ecs_cluster_name) --query "taskArns[0]" \
		| xargs -I % sh -c '{ aws ecs describe-tasks \
			--cluster $(shell terraform output -raw ecs_cluster_name) \
			--task % \
			--query "tasks[0].attachments[0].details[1].value"; }' \
		| xargs -I % sh -c '{ aws ec2 describe-network-interfaces \
			--network-interface-ids % \
			--query "NetworkInterfaces[0].Association.PublicIp"; }' \
		| xargs -I % sh -c '{ echo "PublicIp: %"; }'
