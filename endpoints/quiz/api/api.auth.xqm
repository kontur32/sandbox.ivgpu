module namespace ivgpu.api.auth = 'sandbox/ivgpu/api/auth';

import module namespace request = 'http://exquery.org/ns/request';

declare
  %rest:path( '/sandbox/ivgpu/api/v01/auth' )
  %output:method('xml')
function ivgpu.api.auth:main(){
  <div>
    <ul>{
      for $i in request:cookie-names()
      return
        <li>{$i} : {  request:cookie( $i ) }</li>
     }</ul>
      <ul>{
      for $i in request:header-names()
      return
        <li>{$i} : {  request:header( $i ) }</li>
     }</ul>
  </div>
  
};