export NAMESPACE=default
export DNSNAME=localhost
export URLPATH=demopages
define WEB_PAGES
  index.html: !includefile index.html
  test.html: !includefile test.html
endef
export WEB_PAGES

USER=demo
PASS_CMD=echo test
#PASS_CMD=aws secretsmanager --profile someprofile get-secret-value --secret-id $(USER) --no-cli-pager --output json | jq -r .SecretString

TEMPLATE=template.yaml
DEPLOYMENT_TMP=tmp.yaml

all: install

$(DEPLOYMENT_TMP): $(TEMPLATE) *.html
	pip3 install --user PyYAML
	cat $< | ./yaml-template-includefile.py >$@

install: $(DEPLOYMENT_TMP) update_secret
	kubectl apply -f $(DEPLOYMENT_TMP)

destroy: $(DEPLOYMENT_TMP) delete_secret
	-kubectl delete -f $(DEPLOYMENT_TMP)

clean:
	rm -f $(DEPLOYMENT_TMP)

dump: $(DEPLOYMENT_TMP)
	cat $(DEPLOYMENT_TMP)

update_secret:
	$(PASS_CMD) | htpasswd -i -n "$(USER)" | kubectl --namespace=$(NAMESPACE) create secret generic basicauth-$(URLPATH) --from-file=auth=/dev/stdin --dry-run=client --output=yaml --save-config | kubectl apply -f -

delete_secret:
	-kubectl --namespace=$(NAMESPACE) delete secret basicauth-$(URLPATH)

test_access:
	curl -k -i -u "$(USER):`$(PASS_CMD)`" "https://$(DNSNAME)/$(URLPATH)/"; echo

test_deny:
	curl -k -i "https://$(DNSNAME)/$(URLPATH)/"; echo

.PHONY: all install destroy clean dump update_secret delete_secret test_access test_deny
