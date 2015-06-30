VERSION=	$(shell cat $(VERSION_FILE))
VERSION_FILE=	version.txt

SOURCE=		data/domains.json
DESTINATION=	webusaito.kirei.se:/d/www/www.kirei.se/tls

LIST=		domains.txt
SUMMARY=	summary.json

DOMAINS=	results/$(VERSION)-domains.json
REPORT=		results/$(VERSION)-ssllabs.json
LOGFILE=	results/$(VERSION)-ssllabs.log
REDIRECT=	results/$(VERSION)-redirect.json
DNS=		results/$(VERSION)-dns.json

SCRIPT_SUMMARY=	scripts/summarize-ssllabs.pl
SCRIPT_WEB=	scripts/create-web.pl

TMPFILES=	$(LIST) $(SUMMARY)

TEMPLATE_EN=	templates/en.html
TEMPLATE_SV=	templates/sv.html
I18N=		templates/i18n.json

HTML_EN=	web/report.en.html
HTML_SV=	web/report.sv.html


all:

refresh:
	date +%Y%m%d > $(VERSION_FILE)

scan: $(REPORT)

redirect: $(REDIRECT)

dns: $(DNS)

summary: $(SUMMARY)

web: $(HTML_SV) $(HTML_EN)

save:
	git add $(DOMAINS) $(REPORT) $(LOGFILE) $(REDIRECT) $(DNS)
	git commit -m "update results" $(DOMAINS) $(REPORT) $(LOGFILE) $(REDIRECT) $(DNS) $(VERSION_FILE)

webdist:
	 rsync -av --delete --exclude .DS_Store web/ $(DESTINATION)/

$(REDIRECT): $(LIST)
	perl scripts/check-redirect.pl $(LIST) > $@

$(DNS): $(LIST)
	perl scripts/check-dns.pl $(LIST) > $@

$(REPORT): $(LIST)
	ssllabs-scan \
		--usecache=true --maxage=24 \
		--hostfile=$(LIST) \
		--verbosity=debug \
		>$@ 2>$(LOGFILE)

$(SUMMARY): $(DOMAINS) $(REDIRECT) $(DNS) $(REPORT) $(SCRIPT_SUMMARY)
	perl scripts/summarize-ssllabs.pl \
		--domains $(DOMAINS) \
		--report $(REPORT) \
		--redirect $(REDIRECT) \
		--dns $(DNS) \
		> $@

$(DOMAINS):
	cp $(SOURCE) $@

$(HTML_SV): $(SUMMARY) $(TEMPLATE_SV) $(SCRIPT_WEB) $(I18N)
	perl scripts/create-web.pl \
		--language sv \
		--i18n $(I18N) \
		--template $(TEMPLATE_SV) \
		--summary $(SUMMARY) \
		> $@

$(HTML_EN): $(SUMMARY) $(TEMPLATE_EN) $(SCRIPT_WEB) $(I18N)
	perl scripts/create-web.pl \
		--language en \
		--i18n $(I18N) \
		--template $(TEMPLATE_EN) \
		--summary $(SUMMARY) \
		> $@

$(LIST): $(DOMAINS)
	perl scripts/export-domains-list.pl $(DOMAINS) > $@
	
clean:
	rm -f $(TMPFILES)
