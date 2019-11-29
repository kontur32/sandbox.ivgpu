module namespace ivgpu = 'subjects.Departments.List';

import module namespace rup = 'subjects.Department.Direction' at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

declare variable  $ivgpu:url := 
  function( $id ){ 
    'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.file.get?id=' || $id
  };

declare 
  %rest:path( '/sandbox/ivgpu/file.get/{ $id }' )
function ivgpu:view( $id ){
  let $file := json:parse( fetch:text( $ivgpu:url( $id ) ) )
  let $fileName := iri-to-uri( $file//NAME/text() )
  return
    (
      <rest:response>
        <http:response status="200">
          <http:header name="Content-Disposition" value='{ "attachment; filename=" || $fileName }' />
          <http:header name="Content-type" value="application/octet-stream"/>
        </http:response>
      </rest:response>,
      fetch:binary( $file//DOWNLOAD__URL/text() )
    )
};