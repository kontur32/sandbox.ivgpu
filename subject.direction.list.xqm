module namespace ivgpu = 'subjects.Departments.List';

import module namespace session = "http://basex.org/modules/session";

import module namespace 
  check = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/проверкаНаличияРПД'
    at 'generate.doc/RPD/generate.RPD.check.xqm';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/statistic/lists/subjects/{ $disc }/directions' )
  %rest:query-param( 'dep', '{ $dep }', '21' )
  %rest:query-param( 'year', '{ $year }', '2016,2017,2018,2019,2020' )
  %output:method( 'xhtml' )
function ivgpu:view( $disc, $year, $dep ){

   let $auth := if( session:get( 'login' ) )then( true() )else( false() )
   
   let $years := tokenize( $year, ',' )
 
   let $программы := 
     data:getProgrammData()
     [ Дисциплины/Дисциплина/@Название/data() = web:decode-url( $disc ) ]
     [ @Год = $years ]
   
   let $кафедры := 
     ivgpu:getCSV(
       'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=183523999&amp;single=true&amp;output=csv'
     )

  let $записиДисциплиныПоКафедре :=
       if( $кафедры[ КафедраКод = $dep ]/Дисциплины/text() )
       then(
         ivgpu:getCSV( $кафедры[ КафедраКод = $dep ]/Дисциплины/text() )
         [ Дисциплина/text() = $disc ]
       )
       else()
  
  let $items :=   
    for $i in $программы
    let $дисциплина := $i/Дисциплины/Дисциплина[ @Название/data() = web:decode-url( $disc )  ]
    let $кодКафедры := $дисциплина/@КодКафедры/data()
    where  if( $dep )then( $кодКафедры = $dep )else( true() )
    order by $i/@ФормаОбучения/data()
    order by $дисциплина/@КодКафедры/number( data() )
    
    let $urlРУПа := $i/Файл/@DETAIL__URL/data()
    
    let $urlРУПаЕксель := replace( $urlРУПа, '.plx', '.plx.xls' )
    
    let $check := check:check( $i,  $дисциплина/@КодДисциплины/data() )/item
    
    let $маркер :=
      if( $check )
      then( <span style = 'color : green;'>&#9679;</span> )
      else( <span style = 'color : red;'>&#9679;</span> )
    
    let $hrefUpload := 
      '/sandbox/ivgpu/api/v01/programms/' || $i/Файл/@ID/data() || '/' || web:encode-url( $дисциплина/@КодДисциплины ) || '/comp'
    
    let $кнопкаЗагрузки := 
      if( $check )
       then( 
         <a href = "{ $check/DOWNLOAD_URL/text() }">
          <i class="bi-download" style="font-size: 1.5rem; color: #17a2b8;"/>
         </a>
       )
       else(
         <a class = "btn btn-success" href = '{ $hrefUpload }'>загрузить</a>
       )
    let $ссылкаСтраницаРУПа :=
      string-join(
        ( '/sandbox/ivgpu/api/directions', $i/@Год, $i/@КодНаправления, $i/Файл/@ID, 'аннотации' ),
        '/'
      )
    
    let $преподаватель :=
      ivgpu:преподавательДисциплиныПоНаправлению(
        $записиДисциплиныПоКафедре,
        $i/@КодНаправления/data() 
      )
    let $странцицаПреподавателя := 
      string-join(
        ( '/sandbox/ivgpu/statistic/lists/subjects', $dep, $преподаватель ),
        '/'
      )
    return
       <p class = 'mb-2 ml-4'>
         { $кнопкаЗагрузки } : { $i/@КодНаправления/data() } ({ $i/@ФормаОбучения/data() }, { $i/@Год/data() }) : { $дисциплина/@КодДисциплины/data() } : <a href = '{ $странцицаПреподавателя }'>{ $преподаватель }</a> : <a href = '{ $ссылкаСтраницаРУПа }'>{ $i/@НазваниеПрофиля/data() }</a> (<a href = "{ $urlРУПа }">{ $i/Файл/@ID/data() }</a>, <a href = "{ $urlРУПаЕксель }">excel</a>) : кафедра { $дисциплина/@КодКафедры/data() }
       </p>
  
  let $результат := 
      <div>
        <h2>Дисциплина "{ $disc }" в РУПах { string-join( sort( $years ), ', ' ) } годов приёма</h2>
        <div>Всего: { count( $items ) } шт.</div>
        <div>Кафедра:
          {
           let $кафедры := 
             $программы/Дисциплины/Дисциплина
            [ @Название/data() = web:decode-url( $disc ) ]/@КодКафедры/data()
           for $i in $кафедры
           let $номерКафедры := number( $i )
           order by $номерКафедры
           group by $номерКафедры
           return
             <a href = "?dep={ $i[ last() ] }">{ $i[ last() ] }</a>
          }
        </div>
        <div>Авторизованный пользователь:  { session:get( 'login' ) } (кафедра: {  session:get( 'department' ) } )</div> 
        <div> { $items }</div>  
      </div>
   
   let $tpl := doc( "html/main.tpl.html" )
   return
      $tpl update insert node $результат into .//body
};

declare
  %public
function 
  ivgpu:преподавательДисциплиныПоНаправлению(
    $записиДисциплины as element( record )*,
    $кодНаправления as xs:string
  )
{
  let $преподавательПоНаправлению :=
    $записиДисциплины
    [ Код_направления[ matches( text(), $кодНаправления ) ] ]
    /Преподаватель/text() 

  return
   if( $преподавательПоНаправлению )
   then( $преподавательПоНаправлению[ 1 ] )
   else(
     $записиДисциплины[ not( Код_направления/text() ) ][ 1 ]
     /Преподаватель/text() 
   )
};

declare function ivgpu:getCSV( $path as xs:string ) as element( record )* {
  csv:parse(  
      fetch:text(
        $path 
    ), map{ 'header' : true() } )/csv/record
};