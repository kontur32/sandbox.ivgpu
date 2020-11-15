module namespace jwt = 'sandbox/ivgpu/вопросник/модули/jwt';

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