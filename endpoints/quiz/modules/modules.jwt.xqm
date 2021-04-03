module namespace jwt = 'sandbox/ivgpu/вопросник/модули/jwt';

import module namespace 
  config = 'sandbox/ivgpu/вопросник/модули/config'
    at '../config.xqm';

declare 
  %public
function jwt:buildJWT( $payLoad as xs:string )
  as xs:string
{
  let $secret := config:param( 'secret' )
  return
    jwt:buildJWT( $payLoad, $secret )
};

declare 
  %public
function jwt:buildJWT( $payLoad as xs:string, $secret as xs:string )
  as xs:string
{
  let $h :=
    string( convert:string-to-base64( '{ "alg": "HS256", "typ": "JWT"}' ) )
  let $p :=
    string( convert:string-to-base64(  $payLoad ) )
  let $hash :=
    string( hash:sha256( $h || '.' || $p || $secret ) )
  return
    $h || '.' ||   $p  || '.' || $hash
};


declare
  %public
function jwt:validateJWT( $jwt ){
  let $secret := config:param( 'secret' )
  return
    jwt:validateJWT( $jwt, $secret )
};

declare
  %public
function jwt:validateJWT( $jwt, $secret ){
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

