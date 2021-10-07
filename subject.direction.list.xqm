module namespace ivgpu = 'subjects.Departments.List';

import module namespace session = "http://basex.org/modules/session";

import module namespace
  config = '/sandbox/ivgpu/api/v01/generate/config'
    at 'generate.doc/config.xqm';
    
import module namespace 
  check = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/проверкаНаличияРПД'
    at 'generate.doc/RPD/generate.RPD.check.xqm';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/statistic/lists/subjects/{ $disc }/directions' )
  %rest:query-param( 'dep', '{ $dep }', '21' )
  %rest:query-param( 'deps', '{ $deps }', 'all' )
  %rest:query-param( 'year', '{ $year }', '2016,2017,2018,2019,2020,2021' )
  %output:method( 'xhtml' )
function ivgpu:view( $disc, $year, $dep, $deps ){
   let $auth := if( session:get( 'login' ) )then( true() )else( false() )
   let $years := tokenize( $year, ',' )
   let $программы := 
     data:getProgrammData()
     [ Дисциплины/Дисциплина/@Название/data() = web:decode-url( $disc ) ]
     [ @Год = $years ]
     [ if( $deps != 'all' )then( @Кафедра = $deps )else( true() ) ]
  
  let $кафедры :=
     data:getResourceCSV( config:param( 'ресурс.кафедры' ) )/csv/record
  
  let $записиДисциплиныПоКафедре :=
       if( $кафедры[ КафедраКод = $dep ]/Дисциплины/text() )
       then(
         data:getResourceCSV( $кафедры[ КафедраКод = $dep ]/Дисциплины/text() )
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
    
    let $checkRoot :=
      check:check( $i,  $дисциплина/@КодДисциплины/data(), config:param( 'upload.Directory.Root' ) )/item
    
    let $checkSecondary :=
      check:check( $i,  $дисциплина/@КодДисциплины/data(), config:param( 'upload.Directory.Secondary' ) )/item
    
    let $hrefUpload := 
      '/sandbox/ivgpu/api/v01/programms/' || $i/Файл/@ID/data() || '/' || web:encode-url( $дисциплина/@КодДисциплины ) || '/comp'
    
    let $кнопкаЗагрузкиRoot := 
      if( $checkRoot )
       then( 
         <a class = "btn btn-success" href = "{ $checkRoot/DOWNLOAD_URL/text() }" style = "width: 100px;">скачать</a>
       )
       else(
         <a class = "btn btn-warning" href = '{ $hrefUpload }' style = "width: 100px;">загрузить</a>
       )
    
    let $кнопкаЗагрузкиSecondary := 
      if( $checkSecondary )
       then( 
         <a class = "btn btn-success"  href = "{ $checkSecondary/DOWNLOAD_URL/text() }" style = "width: 100px;">скачать</a>
       )
       else(
         <a class = "btn btn-warning" href = '{ $hrefUpload }' style = "width: 100px;">загрузить</a>
       )
    
    let $ссылкаСтраницаРУПа :=
      string-join(
        ( '/sandbox/ivgpu/api/directions', $i/@Год, $i/@КодНаправления, $i/Файл/@ID, 'rpd' ),
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
    <tr>
       <td style = "width: 100px;">{ $кнопкаЗагрузкиRoot }</td>
       <td style = "width: 100px;">{ $кнопкаЗагрузкиSecondary }</td>
       <td>{ $дисциплина/@КодДисциплины/data() }</td>
       <td class = 'text-center'>{ $i/@КодНаправления/data() }</td>
       <td>{ $i/@ФормаОбучения/data() }, { $i/@Год/data() }</td>
       <td>
          <a href = '{ $ссылкаСтраницаРУПа }'>{ $i/@НазваниеПрофиля/data() }</a> (<a href = "{ $urlРУПа }">"шахты"</a>, <a href = "{ $urlРУПаЕксель }">excel</a>) 
       </td>
       <td class = 'text-center'>{ $дисциплина/@КодКафедры/data() }</td>
       <td><a href = '{ $странцицаПреподавателя }'>{ $преподаватель }</a></td>
    </tr>
  
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
        <div>
          <table class = 'table'>
            <tr class = 'text-center'>
              <th>РПД в Simplex</th>
              <th>РПД в базе УМУ</th>
              <th>Код в РУПе</th>
              <th>Направление</th>
              <th>Форма, год</th>
              <th>РУП</th>
              <th>Кафедра</th>
              <th>Преподаватель</th>
            </tr>
            { $items }
          </table>
        </div>  
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