module  namespace ivgpu = '/sandbox/ivgpu/generate/РПД.Титул';

import module namespace request = 'http://exquery.org/ns/request';

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
declare variable $ivgpu:templateFileFlag := 'РПД.Титул_';
declare variable $ivgpu:separator := '_';
declare variable $ivgpu:уровеньОбразованияПоКоду := 
  function( $кодУровня ){ 
    ( ['03', 'бакалавриат'], [ '04', 'магистратура'], ['05', 'специалитет'] )
    [ .?1 = $кодУровня ]?2
};

declare variable $ivgpu:аттрибутыПрограммы := 
  function( $КодНаправления, $Год ){
    let $аттрибутыПрограмм := 
      fetch:text('https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=0&amp;single=true&amp;output=csv') 
    return
      csv:parse( $аттрибутыПрограмм, map{ 'header' : true() } )
      /csv/record[ КодНаправления = $КодНаправления and Год = $Год ]
  };

declare variable $ivgpu:аттрибутыКаферы := 
  function( $КафедраКод, $Год ){
    let $аттрибутыКаферы := 
      fetch:text('https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=183523999&amp;single=true&amp;output=csv') 
    return
      csv:parse( $аттрибутыКаферы, map{ 'header' : true() } )
      /csv/record[ КафедраКод = $КафедраКод and Год = $Год ]
  };

declare 
  %rest:path( '/sandbox/ivgpu/generate/РПД.Титул/{ $ID }/{ $discID }' )
function ivgpu:main( $ID, $discID ){
 let $data := ivgpu:getData( $ID, $discID )
 let $template := 
   ivgpu:getTemplate(
     $ivgpu:templateFileFlag,
     data:getProgrammData()[ Файл/@ID = $ID ]/@Год/data()
   )
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
      'http://' || request:hostname() || ':' || request:port() ||'/api/v1/ooxml/docx/template/complete'
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
  
  let $disc :=  $Программа/Дисциплины/Дисциплина[ @КодДисциплины = $discID ][1]
  
  let $contentFileName := 
    ( 
      $disc/@Название/data(), 
      $Программа/@КодНаправления/data(),
      $Программа/@НазваниеПрофиля/data()
    )
  
  let $content := content:getContent( $contentFileName, $fields )
  let $кодУровняОбразования := substring(  $Программа/@КодНаправления/data(), 4, 2)
  
  let $аттрибутыПрограммы :=
    $ivgpu:аттрибутыПрограммы(
      $Программа/@КодНаправления/data(), $Программа/@Год/data()
    )
  
  let $аттрибутыКаферы :=
    $ivgpu:аттрибутыКаферы(
      $Программа/@Кафедра/data(), $Программа/@Год/data()
    )
    
  let $fieldsToInsert := 
    (
      <cell id = 'Дисциплина' contentType = 'field'>{ $disc/@Название/data() }</cell>,
      <cell id = 'Направление' contentType = 'field'>{ $Программа/@КодНаправления || ' ' || $Программа/@НазваниеНаправления }</cell>,
      <cell id = 'Профиль' contentType = 'field'>{ $Программа/@НазваниеПрофиля/data() }</cell>,
      <cell id = 'ФормаОбучения' contentType = 'field'>{ $Программа/@ФормаОбучения/data() }</cell>,
      <cell id = 'Семестр' contentType = 'field'>{ $disc/@Семестр/data() }</cell>,
      <cell id = 'ТрудоемкостьЗЕ' contentType = 'field'>{ $disc/@ЗЕТ/data() }</cell>,
      <cell id = 'ТрудоемкостьЧасы' contentType = 'field'>{ $disc/@ЗЕТ/data() * 36 }</cell>,
      <cell id = 'ФГОСПриказДата' contentType = 'field'>{ $аттрибутыПрограммы/ПриказДата/text() }</cell>,
      <cell id = 'ФГОСПриказНомер' contentType = 'field'>{ $аттрибутыПрограммы/ПриказНомер/text() }</cell>,
      <cell id = 'ПрограммаДата' contentType = 'field'>{ $аттрибутыПрограммы/РешениеДата/text() }</cell>,
      <cell id = 'ПрограммаНомер' contentType = 'field'>{ $аттрибутыПрограммы/РешениеНомер/text() }</cell>,
      <cell id = 'КафедраПротоколДата' contentType = 'field'>{ '28.08.' || $Программа/@Год/data() }</cell>,
      <cell id = 'КафедраПротоколНомер' contentType = 'field'>1</cell>,
      <cell id = 'ВыпускающаяКафедраНазвание' contentType = 'field'>
        { $аттрибутыКаферы/КафедраСокращенноеНазвание/text() }
      </cell>,
      <cell id = 'ЗаведующийВыпускающаяКафедра' contentType = 'field'>
        { $аттрибутыКаферы/Заведущий/text() }
      </cell>,
      <cell id = 'Рецензент' contentType = 'field'>Д.В. Пятницкий</cell>,
      <cell id = 'Заведущий' contentType = 'field'>{
        $аттрибутыКаферы[ КафедраКод/text() = $disc/@КодКафедры/data() ]/Заведущий/text()
      }</cell>,
      <cell id = 'УровеньОбразования' contentType = 'field'>{
        $ivgpu:уровеньОбразованияПоКоду( $кодУровняОбразования )
      }</cell>
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
  return
    if( $content/row )
    then(
      $content
        update { if( $Программа/@Год = '2019' and $disc/@КодКафедры = '21' )then( replace value of node ./row[ @id = 'fields' ]/cell[ @id = 'Заведующий' ] with 'С.С. Мишуров' )else() }
        update { insert node $fieldsToInsert into ./row[ @id = 'fields' ] }
        update { insert node $tablesToInsert into ./row[ @id = 'tables' ] }
    )
    else(
      <table>
        <row id = 'fields'/>
        <row id = 'tables'/>
      </table>
        update {
            if( $Программа/@Год = ( '2019', '2020' ) )
            then(
               insert node <cell id = 'Заведующий'>С.С. Мишуров</cell> into ./row[ @id = 'fields' ]
             )
            else()
          }
         update { insert node $fieldsToInsert into ./row[ @id = 'fields' ] }
         update { insert node $tablesToInsert into ./row[ @id = 'tables' ] }
    )
};

declare function ivgpu:getTemplate( $flag, $year ){
  let $templateURL := 
    $rup:getList( $rup:folderList( '62760' ) )
    [ contains( NAME/text(), $flag || $year ) ]/DOWNLOAD__URL/text()
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
    replace( $fileName, '["|№|(|)]', '' )
};