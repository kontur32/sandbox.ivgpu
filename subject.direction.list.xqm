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
  %rest:query-param( 'filter', '{ $filter }', 'no' )
  %rest:query-param( 'year', '{ $year }', '2016,2017,2018,2019,2020' )

  %output:method( 'xhtml' )
function ivgpu:view( $disc, $filter, $year, $dep ){

   let $auth := if( session:get( 'login' ) )then( true() )else( false() )
   
   let $years := tokenize( $year, ',' )
 
   let $программы := 
     data:getProgrammData()
     [ Дисциплины/Дисциплина/@Название/data() = web:decode-url( $disc ) ]
     [ @Год = $years ]
  
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
      '/sandbox/ivgpu/api/v01/generate/РПД.Титул/' || $i/Файл/@ID/data() || '/' || web:encode-url( $дисциплина/@КодДисциплины ) || '/upload'
    let $кнопкаЗагрузки := 
      if( $check )
       then( 
         <a class = "btn btn-info" href = "{ $check/DOWNLOAD_URL/text() }">скачать</a>
       )
       else(
         if( $auth and $кодКафедры = session:get( 'department' ) )
         then( <a class = "btn btn-success" href = '{ $hrefUpload }'>загрузить</a> )
         else()
       )
    return
       <li class = 'mb-2'>
         { $маркер }{ $i/@КодНаправления/data() } : { $дисциплина/@КодДисциплины/data() } : { $кнопкаЗагрузки } : { $i/@НазваниеПрофиля/data() } (<a href = "{ $urlРУПа }">{ $i/Файл/@ID/data() }</a>, <a href = "{ $urlРУПаЕксель }">excel</a>) : { $i/@Год/data() } : { $i/@ФормаОбучения/data() } : кафедра - { $дисциплина/@КодКафедры/data() }
       </li>
  
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
             <a href = "?dep={ $i[ last() ] }&amp;filter={ $filter }">{ $i[ last() ] }</a>
          }
        </div>
        <div>Авторизованный пользователь:  { session:get( 'login' ) } (кафедра: {  session:get( 'department' ) } )</div> 
        <ol> { $items }</ol>  
      </div>
   
   let $tpl := doc( "html/main.tpl.html" )
   return
      $tpl update insert node $результат into .//body
};