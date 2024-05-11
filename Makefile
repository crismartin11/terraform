
BUILD_INIT_FOLDER=lambdas/init_service
BUILD_SAVE_FOLDER=lambdas/save_service

build_init:
	cd ${BUILD_INIT_FOLDER}; \
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o target/bootstrap src/main.go \

zip_init:
	cd ${BUILD_INIT_FOLDER}/target; \
	zip init_service.zip bootstrap

build_save:
	cd ${BUILD_SAVE_FOLDER}; \
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o target/bootstrap src/main.go

zip_save:
	cd ${BUILD_SAVE_FOLDER}/target; \
	zip save_service.zip bootstrap

build_zip_init: build_init zip_init

build_zip_save: build_save zip_save

build: build_zip_init build_zip_save

plan:
	terraform plan -var user_creds='{"client_id":"avaluetest","client_secret":"bvaluetest"}' -out tfplan

apply:
	terraform apply -var user_creds='{"client_id":"avaluetest","client_secret":"bvaluetest"}'

destroy:
	terraform destroy
