module namespace auth = 'statistic.auth';

declare 
  %rest:path( '/sandbox/ivgpu/statistic/login' )
  %rest:query-param( 'redirect', '{ $redirect }', '/sandbox/ivgpu/statistic' )
function auth:login( $redirect ){
  web:redirect( $redirect )
};