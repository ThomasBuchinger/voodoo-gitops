NODE_IP=10.0.0.16
DHCP_IP=10.0.0.187

OUTPUT_DIR=out
YQ_ARGS=--prettyPrint --no-colors --inplace
TALOSCTL="./bin/talosctl"
TALOS_NODECONF=$(OUTPUT_DIR)/controlplane.yaml
TALOS_CONFIG=$(OUTPUT_DIR)/talosconfig
SECRETS = gitops/infra/common-secrets-sealed.yaml \
					gitops/vault/vault-content-cloudflare-sealed.yaml \
					gitops/vault/vault-content-secretids-sealed.yaml \
					gitops/vault/vault-content-github-sealed.yaml

.PHONY: build check-files generate_sealedsecret kubeseal talos-config
build: talos-config kubeseal

bin/talosctl:
	@echo "Installing talosctl to $(TALOSCTL)"
	mkdir -p bin
	curl -Lo $(TALOSCTL) --silent https://github.com/siderolabs/talos/releases/download/v1.2.7/talosctl-linux-amd64
	chmod +x $(TALOSCTL)

$(OUTPUT_DIR)/secrets.yaml:
	$(TALOSCTL) gen secrets --output-file "$(OUTPUT_DIR)/talos-secrets.yaml"

talos-config: check-files bin/talosctl $(OUTPUT_DIR)/secrets.yaml generate_sealedsecret
	mkdir -p $(OUTPUT_DIR)/talos
	$(TALOSCTL) gen config voodoo https://$(NODE_IP):6443 \
		--config-patch=@talos/talos-merge.yaml \
		--output-dir "$(OUTPUT_DIR)" \
		--with-secrets "$(OUTPUT_DIR)/talos-secrets.yaml"
	yq eval $(YQ_ARGS) '.machine.network.interfaces[0].addresses[0] = "$(NODE_IP)/24"'                       $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.cluster.inlineManifests[0].contents = load_str("$(OUTPUT_DIR)/sealed_secret.yaml")' $(TALOS_NODECONF)
	yq eval $(YQ_ARGS) '.contexts.voodoo.endpoints[0] = "$(NODE_IP)"'                                        $(TALOS_CONFIG)

talos-apply:
	$(TALOSCTL) apply-config --insecure --nodes $(DHCP_IP) --file $(TALOS_NODECONF)

talos-update:
	$(TALOSCTL) apply-config --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP) --file $(TALOS_NODECONF)

talos-bootstrap:
	$(TALOSCTL) bootstrap --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP)
talos-reset:
	$(TALOSCTL) reset --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP)
untaint: kueconfig
	KUBECONFIG=./kubeconfig kubectl taint nodes --all node-role.kubernetes.io/controlplane-

kubeconfig:
	$(TALOSCTL) kubeconfig ./kubeconfig --talosconfig $(TALOS_CONFIG) --nodes $(NODE_IP)

check-files:
	@which yq
	mkdir -p $(OUTPUT_DIR)
	test -f sealed.crt
	test -f sealed.key

generate_sealedsecret:
	cp talos/sealed_secrets-template.yaml $(OUTPUT_DIR)/sealed_secret.yaml
	yq eval $(YQ_ARGS) '.stringData."tls.key" = load_str("sealed.key")'  $(OUTPUT_DIR)/sealed_secret.yaml
	yq eval $(YQ_ARGS) '.stringData."tls.crt" = load_str("sealed.crt")'  $(OUTPUT_DIR)/sealed_secret.yaml

kubeseal:  $(SECRETS)
	@echo "Updated Secrets"

$(SECRETS): gitops/%-sealed.yaml: secrets/%.yaml
	@which kubeseal > /dev/null
	@echo "Encrypt '$@' from file '$<'"
	kubeseal --cert sealed.crt -o yaml -f $< > $@
