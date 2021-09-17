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
    
    let $данныеПользователя := 
      let $t := 
         fetch:text(
          'http://iro37.ru/res/tmp/base.php?str=' || tokenize( $token, '\.' )[ 2 ]
        )
      return
       json:parse( $t )/json
    
    let $login := $данныеПользователя/email/text()
    let $пользователи :=
      csv:parse(  
            fetch:text(
              'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=1161096430&amp;single=true&amp;output=csv'
          ), map{ 'header' : true() } )/csv/record
    let $пользователь := $пользователи[ email/text() = $login ]
    let $кафедра := $пользователь/Кафедра/text()
    let $userLogin := if( $login )then( $login )else( 'unknown' )
    let $avatar := $данныеПользователя/photo/text()
    
    let $userName := 
      if( $данныеПользователя/last_name/text() )
      then(
        $данныеПользователя/last_name/text() || ' ' ||
        substring( $данныеПользователя/first_name/text(), 1, 1 ) || '.' ||
        substring( $данныеПользователя/middle_name/text(), 1, 1 ) || '.'
      )
      else( 'John Doe' )
      
    return
      (
        session:set( 'login', $userLogin ),
        session:set( 'userName', $userName ),
        session:set( 'department', $кафедра ),
        session:set( 'avatar', $avatar )
      )
  )
  else(),
  web:redirect( $redirect )
};

declare 
  %rest:path( '/sandbox/ivgpu/statistic/logout' )
  %rest:query-param( 'redirect', '{ $redirect }', 'https://sm.ivgpu.com/sandbox/ivgpu/statistic' )
function auth:logout( $redirect ){
  session:close(),
  let $cookie :=
    request:cookie( 'ivgpu_auth' )
  
  return
    <rest:response>
      <http:response status="302">
        <http:header name="Set-Cookie" value="ivgpu_auth=1; Max-Age=0; path=/; domain=ivgpu.com; secure; httponly; samesite=lax" />
        <http:header name="Location" value="{ $redirect }" />
      </http:response>
    </rest:response>
};