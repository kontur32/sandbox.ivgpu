module namespace ivgpu.api = 'sandbox/ivgpu/api/jwt/validate';

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
         ivgpu.api:validateJWT( $jwt , $secret )
    )
    else(
      <err:JWT02>укажите JWT в параметре 'jwt'</err:JWT02>
    )
};

declare function ivgpu.api:validateJWT( $jwt, $secret ){
  let $t := tokenize( $jwt , '\.' )
  let $isValid := 
    string( hash:sha256( $t[1] || '.' || $t[2] || $secret ) ) = $t[3]
  return
    if( $isValid )
    then(
      json:parse( convert:binary-to-string( xs:base64Binary( $t[2] ) ) )
    )
    else( <err:JWT01><token>{$jwt}</token>не валидный токен</err:JWT01> )
};