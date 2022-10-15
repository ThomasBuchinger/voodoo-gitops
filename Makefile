OUTPUT_DIR=out
YQ_ARGS=--prettyPrint --no-colors --inplace
CLUSTERCTL="./clusterctl"
SECRETS = gitops/infra/common-secrets-sealed.yaml \
					gitops/vault/vault-content-cloudflare-sealed.yaml \
					gitops/vault/vault-content-secretids-sealed.yaml \
					gitops/vault/vault-content-github-sealed.yaml

.PHONY: build config.yaml check-files generate_sealedsecret kubeseal
build: config.yaml kubeseal generate_sidero

config.yaml: check-files generate_sealedsecret
	cp -f k3os/config-template.yaml $(OUTPUT_DIR)/config.yaml
	yq eval $(YQ_ARGS) '.ssh_authorized_keys[0] = load_str("id_rsa.pub")'                       $(OUTPUT_DIR)/config.yaml
	yq eval $(YQ_ARGS) '.k3os.password = load_str("password.txt")'                              $(OUTPUT_DIR)/config.yaml
	yq eval $(YQ_ARGS) '.write_files[0].content = load_str("k3os/network.config")'              $(OUTPUT_DIR)/config.yaml
	yq eval $(YQ_ARGS) '.write_files[1].content = load_str("$(OUTPUT_DIR)/sealed_secret.yaml")' $(OUTPUT_DIR)/config.yaml
	yq eval $(YQ_ARGS) '.write_files[2].content = load_str("k3os/install_flux.sh")'             $(OUTPUT_DIR)/config.yaml
	yq eval $(YQ_ARGS) '.write_files[3].content = load_str("k3os/cron_update_images.sh")'       $(OUTPUT_DIR)/config.yaml

check-files:
	@which yq
	mkdir -p $(OUTPUT_DIR)
	test -f id_rsa.pub
	test -f password.txt
	test -f k3os/network.config
	test -f sealed.crt
	test -f sealed.key

generate_sealedsecret:
	cp k3os/sealed_secrets-template.yaml $(OUTPUT_DIR)/sealed_secret.yaml
	yq eval $(YQ_ARGS) '.stringData."tls.key" = load_str("sealed.key")'  $(OUTPUT_DIR)/sealed_secret.yaml
	yq eval $(YQ_ARGS) '.stringData."tls.crt" = load_str("sealed.crt")'  $(OUTPUT_DIR)/sealed_secret.yaml

kubeseal:  $(SECRETS)
	@echo "Updated Secrets"

$(SECRETS): gitops/%-sealed.yaml: secrets/%.yaml
	@which kubeseal > /dev/null
	@echo "Encrypt '$@' from file '$<'"
	kubeseal --cert sealed.crt -o yaml -f $< > $@

SIDERO_ENV = SIDERO_CONTROLLER_MANAGER_HOST_NETWORK=true \
							SIDERO_CONTROLLER_MANAGER_API_ENDPOINT=10.0.0.16 \
							SIDERO_CONTROLLER_MANAGER_SIDEROLINK_ENDPOINT=10.0.0.16
generate_sidero:
	@which $(CLUSTERCTL) > /dev/null
	$(SIDERO_ENV) $(CLUSTERCTL) generate provider -b talos > gitops/sidero/bootstrap-talos.yaml
	$(SIDERO_ENV) $(CLUSTERCTL) generate provider -c talos > gitops/sidero/controlplane-talos.yaml
	$(SIDERO_ENV) $(CLUSTERCTL) generate provider -i sidero > gitops/sidero/infrastrucure-sidero.yaml