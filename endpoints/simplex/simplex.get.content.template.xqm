module  namespace ivgpu = '/ivgpu/simplex/api/v01/get/шаблонАннотации';

import module namespace functx = "http://www.functx.com";

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at '../../generate.doc/generate.data.xqm';
  

declare
 %rest:path( '/sandbox/ivgpu/generate/Аннотация/{$ID}/{$discID}/шаблон.содержания' )
function ivgpu:main( $ID, $discID ){
  
  let $дисциплина :=
    data:getProgrammData()[ Файл/@ID = $ID ]
    /Дисциплины/Дисциплина[ @КодДисциплины = $discID ][1]
    /@Название/functx:replace-multi( data(), ( ',', ':' ), ( '.', '.' ) )
  
  let $шаблон := 
    fetch:binary(
      ivgpu:getList( '46686' )
      [ NAME/text() = 'Шаблон_содержание.docx' ][ 1 ]/DOWNLOAD__URL/text()
    )

let $ContentDispositionValue := 
      "attachment; filename=" || iri-to-uri( $дисциплина || '_содержание.docx'  )
return
  (
      <rest:response>
        <http:response status="200">
          <http:header name="Content-Disposition" value="{ $ContentDispositionValue }" />
          <http:header name="Content-type" value="application/octet-stream"/>
        </http:response>
      </rest:response>,
      $шаблон
   )
};

declare function  ivgpu:getList( $id ){
  let $url := 
    'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' || $id
  return
    json:parse(
         fetch:text( $url )
      )/json/result/_
};