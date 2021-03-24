module  namespace ivgpu = '/sandbox/ivgpu/api/v01/generate/РПД.Титул';

import module namespace data = '/sandbox/ivgpu/generate/data'
  at '../../generate.doc/generate.data.xqm';

import module  namespace content = '/sandbox/ivgpu/generate/content' 
  at '../../generate.doc/generate.content.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/generate/РПД.Титул/{ $ID }/{ $discID }' )
function ivgpu:main( $ID, $discID ){
  let $кафедры :=
    let $csv := 
      fetch:text( 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=183523999&amp;single=true&amp;output=csv' ) 
      return
        csv:parse( $csv, map{ 'header' : true() } )
        /csv/record

  let $институты :=
    let $csv := 
      fetch:text( 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=790449102&amp;single=true&amp;output=csv' ) 
      return
        csv:parse( $csv, map{ 'header' : true() } )
        /csv/record

  let $программа := data:getProgrammData()[ Файл/@ID = $ID ]
  
  let $дисциплина := $программа/Дисциплины/Дисциплина[ @КодДисциплины = $discID ]
  
  let $кодУровня := tokenize( $программа/@КодНаправления/data(), '\.' )[ 2 ]

  let $уровень :=
    (
      [ '03', 'бакалавриат', 'направлению подготовки' ],
      [ '04', 'магистратура', 'направлению подготовки' ],
      [ '05', 'специалитет', 'специальности' ]
    )

  let $автор :=
    content:getContent(
      (
        $дисциплина/@Название/data(),
        $программа/@КодНаправления/data()
      ),
      ( [ 'Автор', 'field' ], [ 'Рецензент', 'field' ] )
    )
  
  let $выспукающаяКафедра :=
    $кафедры[ КафедраКод = $программа/@Кафедра/data() and Год = '2020' ]

  let $кафедра :=
    $кафедры[ КафедраКод = $дисциплина/@КодКафедры/data() and Год = '2020' ]
  
  let $институт :=
    $институты[ сокращенноеНазвание/text() = $кафедра/Институт/text() ]
  let $направление := 
    ivgpu:camelCase( $программа/@НазваниеНаправления/data() )
  let $рецензент := 
    if( $автор/row[ @id = "fields" ]/cell[ @id = "Рецензент" ]/text() )
    then( $автор/row[ @id = "fields" ]/cell[ @id = "Рецензент" ]/text() )
    else( 'Д.В. Пятницкий' )
  let $видыРабот :=
    map{ '2' : 'дисциплины', '3': 'практики' } 
  let $data := 
    <table>
      <row  id = 'fields'>
        <cell id="кафедра">{ $кафедра/Название_кафедры/text() }</cell>
        <cell id="кафедраРодительный">{ $кафедра/НазваниеРодительный/text() }</cell>
        <cell id="институт">{ $институт/полноеНазваниеРодительный/text() }</cell>
        <cell id="декан">{ $институт/Директор/text() }</cell>
        <cell id="дисциплина">{ $дисциплина/@Название/data() }</cell>
        <cell id="кодНаправления">{ $программа/@КодНаправления/data() }</cell>
        <cell id="названиеНаправления">{ $направление }</cell>
        <cell id="профиль">{ $программа/@НазваниеПрофиля/data() }</cell>
        <cell id="семестр">{ $дисциплина/@Семестр/data() }</cell>
        <cell id="квалификация">{ $уровень[ .?1 = $кодУровня ]?2 }</cell>
        <cell id="названиеУровняПодготовки">{ $уровень[ .?1 = $кодУровня ]?3 }</cell>
        <cell id="форма">{ $программа/@ФормаОбучения/data() }</cell>
        <cell id="видРаботы">{ map:get( $видыРабот,  $дисциплина/@Тип/data() ) }</cell>
       
        
        <cell id="датаПриказа">{ ivgpu:date( $программа/@датаПриказа/data() ) }</cell>
        <cell id="номерПриказа">{ $программа/@номерПриказа/data() }</cell>
        <cell id="датаПротоколаУченогоСовета">{ ivgpu:date( $программа/@датаСовета/data() ) }</cell>
        <cell id="номерПротоколаУченогоСовета">{ $программа/@номерСовета/data() }</cell>
        <cell id="датаПротоколаКафедры">26.05.2020</cell>
        <cell id="номерПротоколаКафедры">8</cell>
        <cell id="заведующийКафедрой">{ $кафедра/Заведущий/text() }</cell>
        <cell id="должностьЗаведующего">{ $кафедра/Должность/text() }</cell>
        <cell id="автор">{ $автор/row[ @id = "fields" ]/cell[ @id = "Автор" ]/text() }</cell>
        <cell id="рецензент">{ $рецензент }</cell>
        <cell id="заведующийВыпускающейКафедры">{ $выспукающаяКафедра/Заведущий/text() }</cell>
         <cell id="должностьЗаведующегоВыспукающей">{ $выспукающаяКафедра/Должность/text() }</cell>
      </row>
      
      <row  id = 'pictures'>
        <cell id="декан">{ content:getSignature( $институт/Директор/text() ) }</cell>
        <cell id="заведующий">{ content:getSignature( $кафедра/Заведущий/text() ) }</cell>
       
        <cell id="заведующийВыпускающей">{ content:getSignature( $выспукающаяКафедра/Заведущий/text() ) }</cell>
       
        <cell id="автор" contentType = "picture">{ content:getSignature( $автор/row[ @id = "fields" ]/cell[ @id = "Автор" ]/text() ) }</cell>
        <cell id="рецензент" contentType = "picture">{ content:getSignature( $рецензент ) }</cell>
      </row>
      
    </table>
  let $fileName := ivgpu:buildOutputFile( $ID, $discID, '.docx' )
  let $ContentDispositionValue := 
      "attachment; filename=" || iri-to-uri( $fileName  )
  return
   (
      <rest:response>
        <http:response status="200">
          <http:header name="Content-Disposition" value="{ $ContentDispositionValue }" />
          <http:header name="Content-type" value="application/octet-stream"/>
        </http:response>
      </rest:response>,
      ivgpu:заполнитьДокумент( $data )
   )
};

declare function ivgpu:camelCase( $строка ){
  upper-case( substring( $строка, 1, 1 ) ) || lower-case( substring( $строка, 2 ) )
};

declare function ivgpu:date( $дата ){
  replace( xs:string( $дата ), '(\d{4})-(\d{2})-(\d{2})',  '$3.$2.$1' )
};

declare function ivgpu:заполнитьДокумент( $data ){
  let $template :=
    fetch:binary(
      'http://dbx.iro37.ru/zapolnititul/api/v1/forms/template/b1c60358-1e6f-4bf2-98dc-21fa2918f22e'
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
  return 
     http:send-request (
        $request,
        'http://localhost:9984/api/v1/ooxml/docx/template/complete'
      )[ 2 ]
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