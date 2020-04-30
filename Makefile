
SRC:=urlshort.cob
PGM:=URLSHORT
CGI:=urlshort.cgi

all: ebcdic datasets cgi
	@echo 'user $(ZUSER) $(ZPASS) \
		cd $(PGM).SOURCE \
		lcd out \
		binary \
		put URLSHOR1 \
		put URLSHOR2 \
		put URLSHOR3 \
		put BUILD \
		put RUN \
		site filetype=jes NOJESGETBYDSN \
		get BUILD BUILDLOG \
		bye' | ftp -inv $(ZHOST)
	@iconv -t utf-8 -f ibm-1047 out/BUILDLOG | sed 's/IEF/\nIEF/g' | grep 'COND CODE'

ebcdic:
	@rm -rf out && mkdir -p out
	@sed 's/ZUSER/$(ZUSER)/g' build.jcl | awk '{printf "%-80s", $$0}' | iconv -f utf-8 -t ibm-1047 >out/BUILD
	@sed 's/ZUSER/$(ZUSER)/g' run.jcl | awk '{printf "%-80s", $$0}' | iconv -f utf-8 -t ibm-1047 >out/RUN
	@awk '{print $0 > "out/urlshor" NR}' RS='*>db2:package' $(SRC)
	@for f in out/urlshor*; do \
		r="`basename $${f} | tr [:lower:] [:upper:]`"; \
		awk '{printf "%-80s", $$0}' $${f} | iconv -f utf-8 -t ibm-1047 >out/$${r}; \
	done

datasets: check-env
	@echo 'user $(ZUSER) $(ZPASS) \
		quote site rec=u \
		quote site lr=32760 \
		quote site blocks \
		quote site blocksi=32760 \
		rm $(PGM).LOAD \
		mkdir $(PGM).LOAD \
		quote site rec=fba \
		quote site lr=133 \
		quote site blocks \
		quote site blocksi=32718 \
		rm $(PGM).OUT \
		mkdir $(PGM).OUT \
		quote site rec=fb \
		quote site lr=80 \
		quote site blocks \
		quote site blocksi=32720 \
		rm $(PGM).SOURCE \
		mkdir $(PGM).SOURCE \
		rm $(PGM).DBRM \
		mkdir $(PGM).DBRM \
		bye' | ftp -inv $(ZHOST)

cgi: $(CGI) check-env
	@sed 's/ZUSER/$(ZUSER)/g' $(CGI) >out/$(CGI)
	@echo 'user $(ZUSER) $(ZPASS) \
		lcd out \
		cd /usr/lpp/internet/server_root/cgi-bin \
		put $(CGI) \
		quote site chmod 755 $(CGI) \
		bye' | ftp -inv $(ZHOST)

test: check-env
	@mkdir -p out
	@sed -e 's/ZUSER/$(ZUSER)/g' \
		-e 's/OUTFILE/RUNOUT/g' \
		-e 's/HTTPMETHOD/POST/g' \
		-e 's;HTTPPATH;/x.cgi?u=http://altavista.com/foobar;g' \
		run.jcl | awk '{printf "%-80s", $$0}' | iconv -f utf-8 -t ibm-1047 >out/TEST
	@echo 'user $(ZUSER) $(ZPASS) \
		cd $(PGM).OUT \
		del RUNOUT \
		cd .. \
		cd SOURCE \
		del TEST \
		lcd out \
		binary \
		put TEST \
		site filetype=jes NOJESGETBYDSN \
		get TEST RUNLOG \
		site filetype=seq \
		cd .. \
		cd OUT \
		get RUNOUT \
		bye' | ftp -inv $(ZHOST)
	@iconv -t utf-8 -f ibm-1047 out/RUNLOG | sed 's/IEF/\nIEF/g' | grep 'COND CODE'
	@iconv -t utf-8 -f ibm-1047 out/RUNOUT | awk '{gsub(/.{133}/,"&\n")}1'

check-env:
	@[ "${ZHOST}" ] || ( 1>&2 echo "ERR: Build host not set"; exit 1 )
	@[ "${ZUSER}" ] || ( 1>&2 echo "ERR: Build user not set"; exit 1 )
	@[ "${ZPASS}" ] || ( 1>&2 echo "ERR: Build password not set"; exit 1 )

clean:
	rm -rf out/
