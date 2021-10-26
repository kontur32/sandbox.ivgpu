module  namespace ivgpu = '/sandbox/ivgpu/generate/Аннотация';

import module namespace request = 'http://exquery.org/ns/request';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../generate.doc/config.xqm';
  
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
  %rest:query-param( 'mode', '{ $mode }', '' ) 
function ivgpu:main( $ID, $discID, $mode ){
 let $программа := data:getProgrammData( $ID )
 let $data := ivgpu:getData( $программа, $discID, $mode )
 let $template := ivgpu:getTemplate( $программа/@Год/data() )
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
  
  let $fileName := ivgpu:buildOutputFile( $ID, $discID, '.docx')
  
  let $ContentDispositionValue := 
      "attachment; filename=" || iri-to-uri( $fileName  )

   let $response := 
   http:send-request (
      $request,
      config:param( 'host' ) || '/api/v1/ooxml/docx/template/complete'
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
  

declare function ivgpu:getData( $Программа as element( Программа ), $discID, $mode ){
  let $кафедры := 
    csv:parse(  
      fetch:text(
        'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=183523999&amp;single=true&amp;output=csv'
    ), map{ 'header' : true() } )/csv/record
  
  let $fields := 
    (
      [ 'Цели', 'field' ], 
      [ 'Задачи', 'table' ], 
      [ 'Содержание', 'table' ], 
      [ 'Результаты', 'table' ],
      if( $mode = 'signature')
      then(
        [ 'Автор', 'field' ], 
        [ 'Автор', 'picture' ]
      )
      else() 
    )
  
  let $disc :=  $Программа/Дисциплины/Дисциплина[ @КодДисциплины = $discID ][1]
  
  let $contentFileName := 
    ( 
      $disc/@Название/data(), 
      $Программа/@КодНаправления/data(),
      $Программа/@НазваниеПрофиля/data()
    )
  
  let $content := content:getContent( $contentFileName, $fields )
  
  let $уровеньОбразования :=
    if( matches( $Программа/@КодНаправления, '\d+.05.\d+' ) )
    then( [ 'специальность', 'Направленность (профиль)' ] )
    else( [ 'направление подготовки', 'Направленность (профиль)'] )
  
  let $fieldsToInsert :=
    (
      <cell id = 'Направление подготовки' contentType = 'field'>{ $уровеньОбразования?1 }</cell>,
      <cell id = 'Профили подготовки' contentType = 'field'>{ $уровеньОбразования?2 }</cell>,
      <cell id = 'Дисциплина' contentType = 'field'>{ $disc/@Название/data() }</cell>,
      <cell id = 'Направление' contentType = 'field'>{ $Программа/@КодНаправления || ' ' || $Программа/@НазваниеНаправления }</cell>,
      <cell id = 'Профиль' contentType = 'field'>{ $Программа/@НазваниеПрофиля/data() }</cell>,
       if( $mode = 'signature' )
       then(
        <cell id = 'ДолжностьРуководителя'>{ $кафедры[ КафедраКод/text() = $disc/@КодКафедры/data() ]/Должность/text() }</cell>,
        <cell id = 'ДолжностьАвтора'>Автор</cell>,
        <cell id = 'Руководитель' >{ $кафедры[ КафедраКод/text() = $disc/@КодКафедры/data() ]/Заведущий/text() }</cell>
      )
      else()
      
    )
    
  let $tablesToInsert := 
    (
      <cell id = 'Компетенции'>
        <table>
          {
            for $r in  $disc//Компетенция
            return
              <row>
                <cell>{ $r/@ШифрКомпетенции || ' - ' || $r/@Название }</cell>            
              </row>
          }
        </table>
      </cell>
    )
  let $picturesToInsert :=
    let $подпись := 
       if( $mode = 'signature' )
       then(
         <cell id = 'Руководитель' contentType="picture">
          {
           content:getSignature( $кафедры[ КафедраКод/text() = $disc/@КодКафедры/data() ]/Заведущий/text() )
           }
         </cell>
       )
       else(
         (
           <row id = 'pictures'>
             <cell id = 'Руководитель' contentType = "picture">
                { content:getSignature( 'Заглушка' ) }
             </cell>,
             <cell id = 'Автор' contentType = "picture">
                { content:getSignature( 'Заглушка' ) }
             </cell>
           </row>
         )
       )
    return
      $подпись
   
  let $result :=
    if( $content/row )
    then(
      $content
        update { insert node $fieldsToInsert into ./row[ @id = 'fields' ] }
        update { insert node $tablesToInsert into ./row[ @id = 'tables' ] }
        update {
           if( $mode = 'signature' )
           then( insert node $picturesToInsert into ./row[ @id = 'pictures' ] )
           else( replace node ./row[ @id = 'pictures' ] with $picturesToInsert )
         }
        
    )
    else(
      <table>
        <row id = 'fields'/>
        <row id = 'tables'/>
        <row id = 'pictures'/>
      </table>
         update { insert node $fieldsToInsert into ./row[ @id = 'fields' ] }
         update { insert node $tablesToInsert into ./row[ @id = 'tables' ] }
         update { insert node $picturesToInsert into ./row[ @id = 'pictures' ] }
    )
  return
      $result
};

declare function ivgpu:getTemplate( $year ){
  let $templateURL := 
    $rup:getList( $rup:folderList( '62760' ) )
    [ starts-with( NAME/text(), 'Аннотация_' || $year ) ]/DOWNLOAD__URL/text()
  return
    fetch:binary( $templateURL )
};

declare function ivgpu:buildOutputFile( $ID, $discID, $format ){
  let $Программа :=  data:getProgrammData()[ Файл/@ID = $ID ]
  let $Дисциплина :=  $Программа/Дисциплины/Дисциплина[ @КодДисциплины = $discID ][1]
  let $АббревиатураПрограммы := 
    $Программа/@НазваниеПрофиля
    /upper-case(
      string-join(
        for-each(
          tokenize( . ), function( $result) { substring( $result, 1, 1 ) }
        ) 
      ) 
    )
 let $fileName := 
    $Программа/@КодНаправления || '_' ||
    $АббревиатураПрограммы || '_' ||
    $Дисциплина/@Название || '_' ||
    $Программа/@Год ||
    $format
  return
    replace( $fileName, '["|№|(|)|,]', '' )
};