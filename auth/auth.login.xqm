module namespace auth = 'statistic.auth';

import module namespace request = "http://exquery.org/ns/request";
import module namespace session = "http://basex.org/modules/session";

declare 
  %rest:path( '/sandbox/ivgpu/statistic/login' )
  %rest:query-param( 'redirect', '{ $redirect }', '/sandbox/ivgpu/statistic' )
function auth:login( $redirect ){
  if( request:cookie( 'ivgpu_auth' ) )
  then(
    let $token := request:cookie( 'ivgpu_auth' )
    let $login := 
      let $t := 
         fetch:text(
          'http://iro37.ru/res/tmp/base.php?str=' || tokenize( $token, '\.' )[ 2 ]
        )
      return
       json:parse( $t )/json/email/text()
    
    let $кафедра :=
      let $пользователи := 
          csv:parse(  
            fetch:text(
              'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=1161096430&amp;single=true&amp;output=csv'
          ), map{ 'header' : true() } )/csv/record
      return
        $пользователи[ email/text() = $login ]/Кафедра/text()
    
    return
      (
        session:set( 'login', $login ),
        session:set( 'department', $кафедра )
      )
  )
  else(),
  web:redirect( $redirect )
};

declare 
  %rest:path( '/sandbox/ivgpu/statistic/logout' )
  %rest:query-param( 'redirect', '{ $redirect }', '/sandbox/ivgpu/statistic' )
function auth:logout( $redirect ){
  session:close(),
  let $cookie :=
    request:cookie( 'ivgpu_auth' )
  
  return
    <rest:response>
        <http:response status="302">
          <http:header name="Set-Cookie" value="ivgpu_auth=1; Max-Age=0; path=/;" />
          <http:header name="Location" value="https://sm.ivgpu.com/sandbox/ivgpu/statistic" />
        </http:response>
      </rest:response>
};