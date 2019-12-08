module  namespace ivgpu = '/sandbox/ivgpu/generate/Аннотация';

import module  namespace 
  content = '/sandbox/ivgpu/generate/content' 
  at 'generate.content.xqm';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.data.xqm';
  
import module namespace 
  rup = 'subjects.Department.Direction' 
    at '../tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

declare variable $ivgpu:contentFileFlag := '_содержание.docx';
declare variable $ivgpu:templateFileFlag := 'Аннотация';
declare variable $ivgpu:separator := '_';

declare 
  %rest:path( '/sandbox/ivgpu/generate/Аннотация/{ $ID }/{ $discID }' )
function ivgpu:main( $ID, $discID ){
 let $data := ivgpu:getData( $ID, $discID )
 let $template := ivgpu:getTemplate( data:getProgrammData()[ Файл/@ID = $ID ]/@Год/data() )
 let $request :=
    <http:request method='post'>
      <http:multipart media-type = "multipart/form-data" >
          <http:header name="Content-Disposition" value= 'form-data; name="template";'/>
          <http:body media-type = "application/octet-stream" >
            { $template }
          </http:body>
          <http:header name="Content-Disposition" value= 'form-data; name="data";'/>
          <http:body media-type = "application/xml">
            { $data }
          </http:body>
      </http:multipart> 
    </http:request>

  let $fileName:= 'titul24.docx'
  let $ContentDispositionValue := 
      "attachment; filename=" || iri-to-uri( $fileName  )

   let $response := 
   http:send-request (
      $request,
      'http://localhost:8984/api/v1/ooxml/docx/template/complete'
    )
  return 
   (
      <rest:response>
        <http:response status="200">
          <http:header name="Content-Disposition" value="{ $ContentDispositionValue }" />
          <http:header name="Content-type" value="application/octet-stream"/>
        </http:response>
      </rest:response>,
      $response[2]
   )
};
  

declare function ivgpu:getData( $ID, $discID ){
  let $Программа :=  data:getProgrammData()[ Файл/@ID = $ID ]
  
  let $fields := 
    (
      [ 'Цели', 'field' ], 
      [ 'Задачи', 'table' ], 
      [ 'Содержание', 'table' ], 
      [ 'Результаты', 'table' ], 
      [ 'Автор', 'field' ], 
      [ 'Заведующий', 'field' ], 
      [ 'Автор', 'picture' ], 
      [ 'Заведующий', 'picture' ]
    )
  
  let $disc :=  $Программа/Дисциплины/Дисциплина[ @КодДисциплины = $discID ]
  
  let $contentFileName := 
    ( 
      $disc/@Название/data(), 
      $Программа/@КодНаправления/data(),
      $Программа/@НазваниеПрофиля/data()
    )
  
  let $content := content:getContent( $contentFileName, $fields )
  
  let $fieldsToInsert :=
    (
      <cell id = 'Дисциплина' contentType = 'field'>{ $disc/@Название/data() }</cell>,
      <cell id = 'Направление' contentType = 'field'>{ $Программа/@КодНаправления || ' ' || $Программа/@НазваниеНаправления }</cell>,
      <cell id = 'Профиль' contentType = 'field'>{ $Программа/@НазваниеПрофиля/data() }</cell>
    )
    
  let $tablesToInsert := 
    (
      <cell id = 'Компетенции'>
        <table>
          {
            for $r in  $disc/Компетенция
            return
              <row>
                <cell>{ $r/@ШифрКомпетенции || ' - ' || $r/@Название }</cell>            
              </row>
          }
        </table>
      </cell>
    )
  return
    if( $content/row )
    then(
      $content
        update { insert node $fieldsToInsert into ./row[ @id = 'fields' ] }
        update { insert node $tablesToInsert into ./row[ @id = 'tables' ] }
    )
    else(
      <table>
        <row id = 'fields'></row>
        <row id = 'tables'></row>
      </table>
         update { insert node $fieldsToInsert into ./row[ @id = 'fields' ] }
         update { insert node $tablesToInsert into ./row[ @id = 'tables' ] }
    )
};

declare function ivgpu:getTemplate( $year ){
  let $templateURL := 
    $rup:getList( $rup:folderList( '62760' ) )
    [ contains( NAME/text(), 'Аннотация_' || $year ) ]/DOWNLOAD__URL/text()
  return
    fetch:binary( $templateURL )
};