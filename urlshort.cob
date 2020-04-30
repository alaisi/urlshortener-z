       id division.
       program-id. urlshort.
       data division.
       local-storage section.
         1 url-param-name pic x value 'u'.
         1 link-param-name pic x value 'l'.
         1 param-value pic x(200).
         1 param-len pic 9(4) binary value 0.
       linkage section.
         1 args pic x(255).
         1 argv redefines args.
            2 argc pic s9(2) binary.
            2 http-method pic x(4).
            2 http-path pic x(249).
       procedure division using args.
           if "POST" = http-method
              call 'getparam' using http-path, url-param-name,
                              by reference param-value, param-len
              call 'postlink' using param-value
           else
              call 'getparam' using http-path, link-param-name,
                              by reference param-value, param-len
              call 'getlink' using param-value, param-len
           end-if
           goback.
       end program urlshort.

       id division.
       program-id. getparam.
       data division.
       local-storage section.
         1 i pic 9(4) binary value 0.
         1 j pic 9(4) binary value 0.
       linkage section.
         1 url-path pic x(255).
         1 param pic x.
         1 value-out pic x(200).
         1 value-len-out pic 9(4) binary.
       procedure division using url-path, param, 
                                value-out, value-len-out.
           perform until i > length of url-path
              compute i = i + 1
              if url-path(i:1) = '?'
                 perform until i > length of url-path
                    compute i = i + 1
                    compute j = i + 1
                    if url-path(i:1) = param and url-path(j:1) = '='
                       compute i = j + 1
                       perform until j > length of url-path
                          compute j = j + 1
                          if url-path(j:1) = '&' or url-path(j:1) = ' '
                             compute value-len-out = j - i 
                             move url-path(i:value-len-out) to value-out
                             goback
                          end-if
                       end-perform
                    end-if
                 end-perform
              end-if
           end-perform
           goback.
       end program getparam.

      *>db2:package
       id division.
       program-id. getlink.
       data division.
       working-storage section.
         1 link-id pic s9(18) binary.
         1 url-var.
            49 url-len pic s9(4) binary value 0.
            49 url pic x(1024).
               exec sql include sqlca end-exec.
       linkage section.
         1 link-param pic x(200).
         1 link-param-len pic 9(4) binary.
       procedure division using link-param, link-param-len.
           move link-param(1:link-param-len) to link-id
           exec sql
              select url into :url-var from links
              where id = :link-id
           end-exec
           if url-len < 1
              display 'Status: 404 Not Found'
              display '{"error": "link_not_found"}'
              goback
           end-if
           display 'Refresh: 0;url=' url(1:url-len)
           goback.
       end program getlink.

      *>db2:package
       id division.
       program-id. postlink.
       data division.
       working-storage section.
         1 baseurl pic x(48)
              value 'http://mainframe.local:8080/cgi-bin/urlshort.cgi'.
         1 link-id pic s9(18) binary value 0.
               exec sql include sqlca end-exec.
       linkage section.
         1 url pic x(200).
       procedure division using url.
           if "http://" not = url(1:7) and "https://" not = url(1:8)
              display 'Status: 400 Bad request'
              display '{"error": "invalid_url"}'
              goback
           end-if
           exec sql
              select id into :link-id from links
              where url = rtrim(:url)
           end-exec
           if link-id < 1
              exec sql
                 select id into :link-id from final table (
                    insert into links (id, url) values (
                       (select next value for link_id_seq 
                          from sysibm.sysdummy1), 
                       rtrim(:url)))
              end-exec
              if sqlcode not = 0
                 display 'Status: 500 Internal Server Error'
                 goback
              end-if
           end-if
           display 'Status: 201 Created'
           display '{"url": "' baseurl '?l=' link-id '"}'
           goback.
       end program postlink.