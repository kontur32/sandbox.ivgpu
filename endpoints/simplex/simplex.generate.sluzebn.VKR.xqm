module  namespace ivgpu = '/sandbox/ivgpu/generate/Служебная/ТемыВКР';

import module namespace request = 'http://exquery.org/ns/request';

import module namespace 
  bitrix.disk = 'bitrix.disk' 
    at '../../modules/bitrix.disk.xqm';

declare variable $ivgpu:folderID := '428956';

declare
  %rest:path( '/sandbox/ivgpu/generate/Служебная/{ $department }/ТемыВКР/{ $group }' )
function ivgpu:main( $department, $group as xs:string ){
 
 let $списокГрупп := 
    bitrix.disk:getFileXLSX( $ivgpu:folderID, map{ 'recursive' : 'yes', 'name' : 'Список групп.xlsx' } )
 
 let $данныеГруппы := 
    $списокГрупп/file/table[ 1 ]/row[ cell[ @label = "Группа" ]/text() = $group  ]/cell
 
 let $группа := 
    bitrix.disk:getFileXLSX( $ivgpu:folderID, map{ 'recursive' : 'yes', 'name' : $group } )
    /file/table[ 1 ]/row
    
 let $data := ivgpu:data( $группа, $данныеГруппы )
 
 let $template := 
  bitrix.disk:getFileBinary( $ivgpu:folderID, map{ 'recursive' : 'yes', 'name' : "Шаблон служебной на темы" } )[ 1 ]
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
  
  let $fileName := 'служебкаТемыВКР-' || $group || '.docx'
  
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

declare function ivgpu:data( $группа, $данныеГруппы ){
   let $сотрудники :=
    csv:parse(
      fetch:text(
        'https://docs.google.com/spreadsheets/d/e/2PACX-1vROdb3IiQ7EkWEIvZ6bAPp9c4-a0j-MrbC8f8pMRQS8BFl3c81gvGoJTpokCD0BRzn7yvfKgmhAmbII/pub?gid=868243229&amp;single=true&amp;output=csv'
      ), map{ 'header' : 'yes'}
    )
    /csv/record
  
  return
  <table>
    <row id = "fields">
      <cell id = "группа">{ $данныеГруппы[ @label = "Группа" ]/text() }</cell>
      <cell id = "курс">{ $данныеГруппы[ @label = "Курс" ]/text() }</cell>
      <cell id = "код направления">{ $данныеГруппы[ @label = "Код направления" ]/text() }</cell>
      <cell id = "название направления">{ $данныеГруппы[ @label = "Название направления" ]/text() }</cell>
      <cell id = "профиль">{ $данныеГруппы[ @label = "Профиль" ]/text() }</cell>
      <cell id = "институт">{ $данныеГруппы[ @label = "Институт" ]/text() }</cell>
    </row>
    <row id = "tables">
      <cell id = "Темы">
        <table>
          {
            for $i in $группа
            count $c
            let $руководитель := 
              $сотрудники[ Фамилия = substring-before( $i/cell[ @label = "ФИО руководителя ВКР" ]/text(), ' ') ][ 1 ]
            let $учанаяСтепеньРуководителя := 
              if( $руководитель/Степень != "" )
              then( $руководитель/Степень || ", ")
              else()
              
            return
              <row>
                <cell>{ $c }.</cell>
                <cell>{ $i/cell[ @label = "Студент" ]/text() }</cell>
                <cell>{ $i/cell[ @label = "Тема ВКР" ]/text() }</cell>
                <cell>{
                 $руководитель/ФИО || ', ' || 
                 $учанаяСтепеньРуководителя || 
                 $руководитель/Должность 
               }</cell>
              </row>
          }
        </table>
      </cell>
    </row>
  </table>
};