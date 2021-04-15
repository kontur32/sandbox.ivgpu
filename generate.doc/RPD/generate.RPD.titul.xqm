module  namespace ivgpu = '/sandbox/ivgpu/api/v01/generate/РПД.Титул';

import module namespace data = '/sandbox/ivgpu/generate/data'
  at '../../generate.doc/generate.data.xqm';

import module  namespace content = '/sandbox/ivgpu/generate/content' 
  at '../../generate.doc/generate.content.xqm';
  
import module  namespace видыУчебнойРаботы = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/видыУчебнойРаботы' 
  at 'lib/uchebRabota.xqm';
  
import module  namespace часыПоТемам = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/часыПоТемам'
  at 'lib/chasiPoTemam.xqm';
  
import module  namespace практические = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/практические' 
  at 'lib/practicheskie.xqm';
  
import module namespace
  смежныеДисциплины = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/смежныеДисциплины' 
  at 'lib/smeznieDisciplini.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/generate/РПД.Титул/{ $ID }/{ $кодДисциплины }' )
  %rest:query-param( 'mode', '{ $mode }', '')
function ivgpu:main( $ID, $кодДисциплины, $mode ){
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
  let $дисциплины := $программа/Дисциплины/Дисциплина
  
  let $дисциплина := 
    ivgpu:дисциплинаЗамена( $дисциплины[ @КодДисциплины = $кодДисциплины ] )
  
  let $кодУровня := tokenize( $программа/@КодНаправления/data(), '\.' )[ 2 ]

  let $уровень :=
    (
      [ '03', 'бакалавр', 'направлению подготовки', 'направление' ],
      [ '04', 'магистр', 'направлению подготовки', 'направление' ],
      [ '05', 'специалист', 'специальности', 'специальность' ]
    )

  let $автор :=
    content:getContent(
      (
        $дисциплина/@Название/data(),
        $программа/@КодНаправления/data(),
        $программа/@НазваниеПрофиля/data()
      ),
      (
        [ 'Автор', 'field' ],
        [ 'Рецензент', 'field' ],
        [ 'Цели', 'field' ], 
        [ 'Задачи', 'table' ],
        [ 'Содержание', 'table' ], 
        [ 'Результаты', 'table' ],
        [ 'Базовые знания', 'table' ],
        [ 'Основная литература', 'table' ],
        [ 'Дополнительная литература', 'table' ],
        [ 'ПО', 'table' ],
        if( $дисциплина//кодВидаРабот/text() = '5' )then(  [ 'Темы курсовых работ', 'table' ])else(),
        [ 'Вопросы промежуточной аттестации', 'table' ],
        [ 'Вопросы для самостоятельного изучения', 'table' ],
        [ 'Темы контрольных работ', 'table' ],
        [ 'МТО', 'table' ]
      )
    ) 
  let $содержание :=
    $автор/row[ @id = "tables" ]
    /cell[ @id = "Содержание" ]/table
 
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
  let $группыКомпетенций :=
    map{
      'ОК' : 'общекультурные',
      'УК' : 'универсальные',
      'ПК' : 'профессиональные'
    }
  let $компетенции := 
      <cell id = 'Компетенции'>
        <table>
          {
            for $r in  $дисциплина//Компетенция
            group by $группа := substring-before( $r/@ШифрКомпетенции, '-' )
            return
              (
                <row>
                  <cell>{  map:get( $группыКомпетенций, $группа ) }</cell>            
                </row>,
                for $rr in $r
                return
                  <row>
                    <cell>{ $rr/@ШифрКомпетенции || ' - ' || $rr/@Название }</cell>            
                  </row>
              )
              
          }
        </table>
      </cell>
 
  let $dd := db:open( 'tmp-simplex', 'выбор' )
    /выбор/Дисциплина
  
  let $выборДисциплин:=
    if( $dd[ @ID = $ID and @КодДисциплины = $кодДисциплины ] )
    then(
      $dd[ @ID = $ID and @КодДисциплины = $кодДисциплины ] 
    )
    else(
      $dd[ @Название = $дисциплина/@Название/data() ]
    )
  
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
        <cell id="уровеньПодготовки">{ $уровень[ .?1 = $кодУровня ]?4 }</cell>
        <cell id="названиеУровняПодготовки">{ $уровень[ .?1 = $кодУровня ]?3 }</cell>
        <cell id="форма">{ $программа/@ФормаОбучения/data() }</cell>
        <cell id="видРаботы">{ map:get( $видыРабот,  $дисциплина/@Тип/data() ) }</cell>
        
        <cell id="министерство">{ 
          if(  $программа/@датаПриказа/data() < '2018-05-15' )
          then(
            'Министерства образования и науки Российского Федерации'
          )
          else(
            'Министерства науки и высшего образования Российской Федерации'
          )
        }</cell>
        <cell id="датаПриказа">{ ivgpu:date( $программа/@датаПриказа/data() ) }</cell>
        <cell id="номерПриказа">{ $программа/@номерПриказа/data() }</cell>
        <cell id="датаПротоколаУченогоСовета">
          { ivgpu:date( $программа/@датаСовета/data() ) }
        </cell>
        <cell id="номерПротоколаУченогоСовета">{ $программа/@номерСовета/data() }</cell>
        <cell id="датаПротоколаКафедры">{ $кафедра/ДатаПротокола/text() }</cell>
        <cell id="номерПротоколаКафедры">{ $кафедра/НомерПротокола/text() }</cell>
        
        <cell id="годНачалаПодготовки">{ $программа/@Год/data() }</cell>
         
        <cell id="заведующийКафедрой">{ $кафедра/Заведущий/text() }</cell>
        <cell id="должностьЗаведующего">{ $кафедра/Должность/text() }</cell>
        <cell id="автор">{ $автор/row[ @id = "fields" ]/cell[ @id = "Автор" ]/text() }</cell>
        <cell id="рецензент">{ $рецензент }</cell>
        
        <cell id="заведующийВыпускающейКафедры">{ $выспукающаяКафедра/Заведущий/text() }</cell>
        <cell id="выпускающаяКафедра">
          { $выспукающаяКафедра/КафедраСокращенноеНазвание/text() }
        </cell>
        <cell id="должностьЗаведующегоВыспукающей">
          { $выспукающаяКафедра/Должность/text() }
        </cell>
        
        <cell id="цели">
          { $автор/row[ @id = "fields" ]/cell[ @id = "Цели" ]/text() }
        </cell>
        
        <cell id="блокДисциплины">
          { ivgpu:блокДисциплины( $кодДисциплины, $дисциплина/@Название/data() )}
        </cell>
        
        <cell id="кодДисциплины">{ $кодДисциплины }</cell>
        
        <cell id = "дисциплиныДо">
          { let $дисциплиныДо := 
            string-join( смежныеДисциплины:дисциплиныДо( $дисциплина, $дисциплины, $выборДисциплин ), ', ' )
            return
              if( normalize-space( $дисциплиныДо ) )then( $дисциплиныДо )else( 'программы полного общего или профессионального образования' )
          
        }
        </cell>
        <cell id = "дисциплиныПосле">
          { 
            let $после := 
            string-join( смежныеДисциплины:дисциплиныПосле( $дисциплина, $дисциплины, $выборДисциплин), ', ' )
            return
             if( $после != "" )then( $после || ', а также для выполнения выпускной квалификационной работы' )else( 'для выполнения выпускной квалификационной работы' )
           }
        </cell>
        
        <cell id="зачетныеЕдиницыВсего">{ $дисциплина/@ЗЕТ/data() }</cell>
        <cell id="часовВсего">{ $дисциплина/@ЗЕТ/data() * 36 }</cell>
        <cell id="формыКонтроля">{ string-join( distinct-values( $дисциплина/видыРабот/видРабот[ кодВидаРабот[ text() = ( '1', '2', '3', '4', '5' )] ]/названиеВидаРабота/text() ), ', ' )}</cell>
        
        <cell id="темыКурсовыхРабот">{ if( $дисциплина//кодВидаРабот/text() = '5' )then()else('Курсовая работа не предусмотрена.' ) }</cell>
        <cell id="вопросыПромежуточнойАттестации">{ if( $автор/row[ @id = "tables" ]/cell[ @id = 'Вопросы промежуточной аттестации']/table//cell/text() != "" )then()else( 'В соответствии с ФОС.' ) }</cell>
         <cell id="вопросыДляСамостоятельногоИзучения">{ if( $автор/row[ @id = "tables" ]/cell/table[ @id = 'Вопросы для самостоятельного изучения']//cell/text() != "" )then()else( 'В соответствии с ФОС.' ) }</cell>
         <cell id="темыКонтрольныхРабот">{ if( $автор/row[ @id = "tables" ]/cell/table[ @id = 'Темы контрольных работ']/row )then()else( 'В соответствии с ФОС.' ) }</cell>
      </row>
      
      <row  id = 'tables'>
        { $автор/row[ @id = "tables" ]/cell }
        { $компетенции }
        <cell id = "Учебная работа">{
          видыУчебнойРаботы:учебнаяРабота( $дисциплина )
        }</cell>
        {
          if( $содержание )
          then(
            <cell id = "Тематический план">{
          часыПоТемам:часыПоТемам( $содержание, $дисциплина )
            }</cell>,
            <cell id = "Практические">{
              практические:практические( $содержание, $дисциплина )
            }</cell>
          )
          else()
        }
      </row>
      
      <row  id = 'pictures'>
        <cell id="декан">{ content:getSignature( 'Печать-' || $институт/Директор/text() ) }</cell>
        <cell id="заведующий">{ content:getSignature( $кафедра/Заведущий/text() ) }</cell>
       
        <cell id="заведующийВыпускающей">
          { content:getSignature( $выспукающаяКафедра/Заведущий/text() ) }
        </cell>
       
        <cell id="автор" contentType = "picture">{ content:getSignature( $автор/row[ @id = "fields" ]/cell[ @id = "Автор" ]/text() ) }</cell>
        <cell id="рецензент" contentType = "picture">{ content:getSignature( $рецензент ) }</cell>
      </row>
    </table>
  
  let $fileName := ivgpu:buildOutputFile( $ID, $кодДисциплины, '.docx' )
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
      ivgpu:заполнитьДокумент( $data, $mode )
   )
};

declare function ivgpu:camelCase( $строка ){
  upper-case( substring( $строка, 1, 1 ) ) || lower-case( substring( $строка, 2 ) )
};

declare function ivgpu:date( $дата ){
  replace( xs:string( $дата ), '(\d{4})-(\d{2})-(\d{2})',  '$3.$2.$1' )
};

(: 5c56c1cd-4572-4be5-a5b7-f021eeb4509a b1c60358-1e6f-4bf2-98dc-21fa2918f22e:)
declare function ivgpu:заполнитьДокумент( $data, $mode ){

  let $templateID := 
    if( $mode = 'dev' )
    then( '5c56c1cd-4572-4be5-a5b7-f021eeb4509a' )
    else( 'b1c60358-1e6f-4bf2-98dc-21fa2918f22e' )
  
  let $template :=
    fetch:binary(
      'http://dbx.iro37.ru/zapolnititul/api/v1/forms/template/' || $templateID
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
 let $формыОбучения := 
   map{
     'очная' : 'o',
     'заочная' : 'z',
     'очно-заочная' : 'v'
   }
 let $fileName := 
   map:get( $формыОбучения, $Программа/@ФормаОбучения/data() ) || '_' ||
    replace( $Программа/@КодНаправления, '\.', '' ) || '_' ||
    $АббревиатураПрограммы || '_' ||
    $Программа/@Год || '_' ||
    $Дисциплина/@Название || 
    $format
  return
    replace( $fileName, '["|№|(|)|,]', '' )
};

declare
  %private
function
ivgpu:блокДисциплины(
  $кодДисциплины as xs:string,
  $названиеДисциплины as xs:string
){
  let $практики := 
    map{
      'У' : 'Учебная (ознакомительная)',
      'П' : 'Производственная',
      'Пд' : 'Преддипломная'
    }
  let $базовыйКод := 
    let $t := tokenize( $кодДисциплины, '\.')
    return
      if( count( $t ) >= 3 )
      then(
        string-join( $t[ position() <= 2 ], '.' )
      )
      else( substring-before( $кодДисциплины, ' ') )
  return
    switch( $базовыйКод )
    case 'Б1.О'
      return
        "Дисциплина «" || $названиеДисциплины || "» (" || $кодДисциплины || ") относится к обязательной части блока Дисциплины (модули) рабочего учебного плана."
    case 'Б1.В'
      return
        "Дисциплина «" || $названиеДисциплины || "» (" || $кодДисциплины || ") относится к дисциплинам части, формируемой участниками образовательных отношений блока Дисциплины (модули) рабочего учебного плана."
    case 'ФТД.В'
      return
        "Дисциплина «" || $названиеДисциплины || "»(" || $кодДисциплины || ") относится к блоку Факультативные дисциплины."
    case 'Б2.В'
      return
        map:get( $практики, replace( $кодДисциплины, '.*(У|П.{0,1})\)', '$1' ) ) || 
        " практика "  || "(" || $кодДисциплины || ") относится к обязательной части блока Практика рабочего учебного плана."
    case 'Б3.В'
      return
        "Выполнение и защита выпускной квалификационной работы " || "(" || $кодДисциплины || ") относится к блоку Государственная итоговая аттестация рабочего учебного плана."
    default 
      return ""
};

declare function ivgpu:дисциплинаЗамена( $дисциплина as element( Дисциплина ) ){
  let $названия :=
  map{
    '1' : 'экзамен',
    '2' : 'зачет',
    '3' : 'контрольная работа',
    '4' : 'курсовой проект',
    '5' : 'курсовая работа'
  }

let $видыРаботЗамена :=
  for $i in $дисциплина/видыРабот/видРабот
  let $замена :=
    if( map:get( $названия, $i/кодВидаРабот/text() ) )
    then( map:get( $названия, $i/кодВидаРабот/text() ) )
    else( $i/названиеВидаРабота/text() )
  return
    $i update replace value of node ./названиеВидаРабота with $замена
return
  $дисциплина update replace node ./видыРабот with <видыРабот>{ $видыРаботЗамена }</видыРабот>
};