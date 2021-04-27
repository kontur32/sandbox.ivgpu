module namespace check = "check";

import module namespace request = "http://exquery.org/ns/request";
import module namespace session = "http://basex.org/modules/session";

declare 
  %perm:check( "/sandbox/ivgpu/statistic" )
function check:userArea(){
 let $token := request:cookie( 'ivgpu_auth' )
 return
   if( $token and not( session:get( 'login' ) ) )
   then(
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
      let $пользователь := 
        if( $login )then( $login )else( 'unknown' )
      return
        (
          session:set( 'login', $пользователь ),
          session:set( 'department', $кафедра )
        )
     )
     else()
};