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
       json:parse( $t )
    return
      session:set( 'login', $login )
  )
  else(),
  web:redirect( $redirect )
};