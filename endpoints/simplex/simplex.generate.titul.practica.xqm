module  namespace ivgpu = '/sandbox/ivgpu/generate/Титул/ПреддипломнаяПрактика';

import module namespace request = 'http://exquery.org/ns/request';

import module namespace 
  bitrix.disk = 'bitrix.disk' 
    at '../../modules/bitrix.disk.xqm';

declare variable $ivgpu:folderID := '428956';

declare
  %rest:path( '/sandbox/ivgpu/generate/титул/преддипломная/{ $group }/{ $student }' )
function ivgpu:main( $student as xs:string, $group as xs:string ){
 
 let $списокГрупп := 
    bitrix.disk:getFileXLSX( $ivgpu:folderID, map{ 'recursive' : 'yes', 'name' : 'Список групп.xlsx' } )
 
 let $данныеГруппы := 
    $списокГрупп/file/table[ 1 ]/row[ cell[ @label = "Группа" ]/text() = $group  ]/cell
 
 let $группа := 
    bitrix.disk:getFileXLSX( $ivgpu:folderID, map{ 'recursive' : 'yes', 'name' : $group } )
    /file/table[ 1 ]/row
 
 let $данныеСтудента :=
  $группа[ cell[ @label = "Студент" ] = $student ]
     
 let $data := ivgpu:data( $данныеСтудента, $данныеГруппы )
 
 let $template := 
  bitrix.disk:getFileBinary( $ivgpu:folderID, map{ 'recursive' : 'yes', 'name' : "Шаблон титула отчета по практике" } )[ 1 ]
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
  
  let $fileName := 'ТитулОтчетПоПреддипломной-' || $group || '.docx'
  
  let $ContentDispositionValue := 
      "attachment; filename=" || iri-to-uri( $fileName  )

   let $response := 
   http:send-request (
      $request,
      'http://dbx.iro37.ru/api/v1/ooxml/docx/template/complete'
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

declare function ivgpu:data( $данныеСтудента, $данныеГруппы ){
  let $fio := tokenize( $данныеСтудента/cell[ @label = "Студент" ]/text() )
  let $fio2 := 
    substring( $fio[ 2 ], 1, 1 ) || '.' ||
    substring( $fio[ 3 ], 1, 1) || '. ' ||
    $fio[ 1 ]
  return
    
  <table>
    <row id = "fields">
      <cell id = "студент">{ $fio2 }</cell>
      <cell id = "руководитель">{ $данныеСтудента/cell[ @label = "ФИО руководителя ВКР" ]/text() }</cell>
      <cell id = "группа">{ $данныеГруппы[ @label = "Группа" ]/text() }</cell>
      <cell id = "курс">{ $данныеГруппы[ @label = "Курс" ]/text() }</cell>
      <cell id = "код направления">{ $данныеГруппы[ @label = "Код направления" ]/text() }</cell>
      <cell id = "название направления">{ $данныеГруппы[ @label = "Название направления" ]/text() }</cell>
      <cell id = "профиль">{ $данныеГруппы[ @label = "Профиль" ]/text() }</cell>
      <cell id = "институт">{ $данныеГруппы[ @label = "Институт" ]/text() }</cell>
    </row>
  </table>
};