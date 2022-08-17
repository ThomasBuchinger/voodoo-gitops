OUTPUT_DIR=out
YQ_ARGS=--prettyPrint --no-colors --inplace

.PHONY: config.yaml check-files generate-secrets
config.yaml: check-files generate_secret
	cp -f k3os/config-template.yaml $(OUTPUT_DIR)/config.yaml
	yq eval $(YQ_ARGS) '.ssh_authorized_keys[0] = load_str("id_rsa.pub")'                       $(OUTPUT_DIR)/config.yaml
	yq eval $(YQ_ARGS) '.k3os.password = load_str("password.txt")'                              $(OUTPUT_DIR)/config.yaml
	yq eval $(YQ_ARGS) '.write_files[0].content = load_str("k3os/network.config")'              $(OUTPUT_DIR)/config.yaml
	yq eval $(YQ_ARGS) '.write_files[1].content = load_str("k3os/update_manifests.sh")'         $(OUTPUT_DIR)/config.yaml
	yq eval $(YQ_ARGS) '.write_files[2].content = load_str("$(OUTPUT_DIR)/sealed_secret.yaml")' $(OUTPUT_DIR)/config.yaml

check-files:
	@which yq
	mkdir -p $(OUTPUT_DIR)
	test -f id_rsa.pub
	test -f password.txt
	test -f k3os/network.config
	test -f sealed.crt
	test -f sealed.key

generate_secret:
	cp k3os/sealed_secrets-template.yaml $(OUTPUT_DIR)/sealed_secret.yaml
	yq eval $(YQ_ARGS) '.stringData."tls.key" = load_str("sealed.key")'  $(OUTPUT_DIR)/sealed_secret.yaml
	yq eval $(YQ_ARGS) '.stringData."tls.crt" = load_str("sealed.crt")'  $(OUTPUT_DIR)/sealed_secret.yaml

