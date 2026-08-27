.PHONY: verify bootstrap smoke destroy

verify:
	./scripts/verify.sh

bootstrap:
	./scripts/bootstrap-local.sh

smoke:
	./scripts/smoke-test.sh

destroy:
	./scripts/destroy-local.sh
