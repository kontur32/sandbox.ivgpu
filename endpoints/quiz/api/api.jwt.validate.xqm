module namespace ivgpu.api = 'sandbox/ivgpu/api/jwt/validate';

import module namespace request = 'http://exquery.org/ns/request';

import module namespace 
  jwt = 'sandbox/ivgpu/вопросник/модули/jwt'
    at '../modules/modules.jwt.xqm';

(:
  declare
  %rest:path( '/sandbox/ivgpu/api/v01/jwt/validate/token' )
  %output:method('xml')
  %rest:query-param( 'short-link', '{ $shortLink }', '' )
function ivgpu.api:validateToken( $shortLink as xs:string ){
  let $h :=
    http:send-request(
      <http:request method='get'
           href= "{ $shortLink }">
        </http:request>
    )[ 1 ]/child::*[ @name = "Location"]/@value/data()
  
  let $path := 
    'http://' || request:hostname() ||':' || request:port() || '/sandbox/ivgpu/api/v01/jwt/validate?jwt=' || web:encode-url( substring-after( $h, '://' ) ) 
  
  return
     http:send-request(
        <http:request method='get'
             href= "{ $path }">
          </http:request>
      )[ 2 ]
};
:)


(: проверка по ссылке :)
declare
  %rest:path( '/sandbox/ivgpu/api/v01/jwt/validate/short-link' )
  %output:method('xml')
  %rest:query-param( 'short-url', '{ $shortLink }', '' )
function ivgpu.api:validateShortLink( $shortLink as xs:string ){
  let $h :=
    http:send-request(
      <http:request method='get'
           href= "{ $shortLink }">
        </http:request>
    )[ 1 ]/child::*[ @name = "Location"]/@value/data()
  
  let $path := 
    'http://' || request:hostname() ||':' || request:port() || '/sandbox/ivgpu/api/v01/jwt/validate?jwt=' || web:encode-url( substring-after( $h, 'jwt=') )
  
  return
     http:send-request(
        <http:request method='get'
             href= "{ $path }">
          </http:request>
      )[ 2 ]
};

declare
  %rest:path( '/sandbox/ivgpu/api/v01/jwt/validate' )
  %output:method('xml')
  %rest:query-param( 'jwt', '{ $jwt }', '' )
function ivgpu.api:validate( $jwt as xs:string ){
  let $secret := 'secret'
  return
    if( $jwt != '' )
    then(
        jwt:validateJWT( $jwt , $secret )
    )
    else(
      <err:JWT02>укажите JWT в параметре 'jwt'</err:JWT02>
    )
};