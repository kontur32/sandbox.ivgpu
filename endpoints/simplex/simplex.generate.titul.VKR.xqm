module  namespace ivgpu = '/sandbox/ivgpu/generate/Титул/ВКР';

import module namespace request = 'http://exquery.org/ns/request';

import module namespace 
  bitrix.disk = 'bitrix.disk' 
    at '../../modules/bitrix.disk.xqm';

declare variable $ivgpu:folderID := '428956';

declare
  %rest:path( '/sandbox/ivgpu/generate/титул/ВКР/{ $group }/{ $student }' )
function ivgpu:main( $student as xs:string, $group as xs:string ){
 
 let $списокГрупп := 
    bitrix.disk:getFileXLSX( $ivgpu:folderID, map{ 'recursive' : 'yes', 'name' : 'Список групп.xlsx' } )
 
 let $данныеГруппы := 
    $списокГрупп/file/table[ 1 ]/row[ cell[ @label = "Группа" ]/text() = $group  ]/cell
 
 let $группа := 
    bitrix.disk:getFileXLSX( $ivgpu:folderID, map{ 'recursive' : 'yes', 'name' : $group || '.*xlsx$' } )
    /file/table[ 1 ]/row
 
 let $данныеСтудента :=
  $группа[ cell[ @label = "Студент" ]/normalize-space(text()) = normalize-space($student) ]

 let $data := ivgpu:data( $данныеСтудента, $данныеГруппы )
 
 let $template := 
  bitrix.disk:getFileBinary( $ivgpu:folderID, map{ 'recursive' : 'yes', 'name' : "Шаблон титула ВКР" } )[ 1 ]
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
  
  let $fileName := 'ТитулВКР-' || $group || '.docx'
  
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
  let $руководитель := 
    ivgpu:руководитель(
      $данныеСтудента/cell[ @label = "ФИО руководителя ВКР" ]/text()
    )
  let $ученаяСтепеньРуководителя := 
    if($руководитель/Степень != "")
    then($руководитель/Степень)
    else()
  let $ученоеЗваниеРуководителя := 
    if($руководитель/Звание != "")
    then($руководитель/Звание)
    else()
  let $должностьРуководителя := 
    if($руководитель/Звание != "")
    then($руководитель/Звание)
    else()
  let $data :=  
    <table>
      <row id = "fields">
        <cell id = "ФИО_студента">{ $fio }</cell>
        <cell id = "ФИО_студента_короткое">{ $fio2 }</cell>
        <cell id = "ФИО_руководителя">{ $руководитель/ФИО/text() }</cell>
        <cell id = "должность_руководителя">{ $руководитель/Должность/text() }</cell>
        <cell id = "ученая_степень_звание_руководителя">{ string-join(($ученаяСтепеньРуководителя, $ученоеЗваниеРуководителя), ', ') }</cell>
        <cell id = "Тема_ВКР">{ $данныеСтудента/cell[ @label = "Тема ВКР" ]/text() }</cell>
        <cell id = "Группа">{ $данныеГруппы[ @label = "Группа" ]/text() }</cell>
        <cell id = "курс">{ $данныеГруппы[ @label = "Курс" ]/text() }</cell>
        <cell id = "код направления">{ $данныеГруппы[ @label = "Код направления" ]/text() }</cell>
        <cell id = "Направление_подготовки">{ $данныеГруппы[ @label = "Название направления" ]/text() }</cell>
        <cell id = "Профиль_подготовки">{ $данныеГруппы[ @label = "Профиль" ]/text() }</cell>
        <cell id = "институт">{ $данныеГруппы[ @label = "Институт" ]/text() }</cell>
        <cell id = "Зачетка">{ $данныеСтудента/cell[ @label = "Зачетка" ]/text() }</cell>
      </row>
    </table>
  return
    $data
};

declare function ivgpu:руководитель($фиоРуководителя) as element(record)*{
  let $сотрудники :=
    csv:parse(
      fetch:text(
        'https://docs.google.com/spreadsheets/d/e/2PACX-1vROdb3IiQ7EkWEIvZ6bAPp9c4-a0j-MrbC8f8pMRQS8BFl3c81gvGoJTpokCD0BRzn7yvfKgmhAmbII/pub?gid=868243229&amp;single=true&amp;output=csv'
      ), map{ 'header' : 'yes'}
    )
    /csv/record
    
  let $руководитель := 
      $сотрудники[ Фамилия/text() = substring-before( $фиоРуководителя, ' ') ][ 1 ]
  return
    $руководитель
};