#!/bin/sh

eval 'cgiparse -init'
out="O$(echo $$|cut -c1-7)"

# submit jcl batch job
method="$(printf '%-4s\n' $REQUEST_METHOD)"
path="$(echo $DOCUMENT_URI | sed 's;/cgi-bin;;g')"
cat //\'ZUSER.URLSHORT.SOURCE\(RUN\)\' \
    | sed "s/OUTFILE/$out/g" \
    | sed "s/HTTPMETHOD/$method/g" \
    | sed "s;HTTPPATH;$path;g" \
    | submit >/dev/null 2>&1

# poll for output file
function get_response {
    cat //\'ZUSER.URLSHORT.OUT\($out\)\' \
        | grep -v '^[ ]*$' \
        | sed 's/[ ]+$//g' 2>/dev/null
}
response="$(get_response)"
while [ -z "$response" ]; do
    sleep 1
    response="$(get_response)"
done

# send http headers and body
echo "Content-Type: text/json"
echo "$response" | grep -E '^[a-zA-Z0-9-]+: .+'
echo
echo "$response" | grep -Ev '^[a-zA-Z0-9-]+: .+'