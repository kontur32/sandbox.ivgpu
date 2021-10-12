module namespace ivgpu = 'subjects.Departments.List';

import module namespace
  config = '/sandbox/ivgpu/api/v01/generate/config'
    at 'generate.doc/config.xqm';
  
import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at 'generate.doc/generate.data.xqm';

import module namespace 
  rup = 'subjects.Department.Direction' 
    at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/statistic/lists/subjects/{ $id }' )
  %rest:query-param( 'year', '{ $year }', '2017,2018,2019,2020,2021' )
  %rest:query-param( 'deps', '{ $deps }', 'all' )
  %rest:query-param( 'mode', '{ $mode }', 'all' )
  %rest:query-param( 'host', '{ $host }', 'all' )
  %output:method( 'xhtml' )
function ivgpu:view( $id, $year, $deps, $mode, $host ){
    
   let $кафедры :=
     data:getResourceCSV( config:param( 'ресурс.кафедры' ), map{ 'mode' : 'refresh' } )/csv/record
   
   let $кафедра := $кафедры[ КафедраКод =  $id ]/КафедраСокращенноеНазвание/text()

   let $дисциплины :=
     if( $кафедры[ КафедраКод = $id ]/Дисциплины/text() )
     then(
       data:getResourceCSV( $кафедры[ КафедраКод = $id ]/Дисциплины/text(), map{ 'mode' : 'refresh' } )
       /csv/record
     )
     else()
   
   
   let $fileContentList :=
    rup:getFileContentList( '46686' )
    /NAME/
    replace( normalize-space( substring-before( text(), '_' ) ), ':', '_' )
   
   let $years := tokenize( $year, ',' )
   let $программы := 
     data:getProgrammData()
     [ @Год = $years ]
     [  if( $deps != 'all' )then( @Кафедра = $deps )else( true() ) ]
     /Дисциплины/Дисциплина[ @КодКафедры = $id ]
     
   let $list := distinct-values( $программы/@Название/data() )
   let $countTotal := count( $программы )
   let $программыКоличество := 
     for $i in $list
     return
       [ $i, count( $программы[ @Название = $i ] ) ]
   
   let $items :=    
     for $i in $программыКоличество
     where if( $mode = 'all' )then( true() )else( not( $i?1 = $fileContentList ) )
     where if( $host = 'all' )then( true() )else( not( $дисциплины[ Дисциплина = $i?1 ]/Преподаватель/text() ) )
     
     order by $i?2 descending
     let $заполнена := 
       if( $i?1 = $fileContentList  )
       then( [ '', 'font-weight: bold;' ] )
       else( [ '', 'font-weight: normal;' ] )
     let $преподаватели := 
       for $преподаватель in $дисциплины[ Дисциплина = $i?1 ]/Преподаватель/text()
       let $href := '/sandbox/ivgpu/statistic/lists/subjects/' || $id || '/' || $преподаватель
       return
         <a href = "{ $href }"> { $преподаватель }</a>
     
     let $href2 :=
       web:create-url(
         '/sandbox/ivgpu/statistic/lists/subjects/' || $i?1 || '/directions',
         map{
           'dep' : $id,
           'deps' : $deps
         }
       )
     return
       <li style = "{ $заполнена?2 }">
         <a href = "{ $href2 }">{ $i?1 }</a>
         { ' : ' || $i?2 || ' : ' }{ $преподаватели }
       </li>
   let $baseURL := '/sandbox/ivgpu/statistic/lists/subjects/' || $id
   let $списокКафедр :=
     for $i in $кафедры
     let $код := $i/КафедраКод/text()
     let $href := $baseURL || '?deps=' || $код
     return
       if( $deps = $код )
       then( <b>{ $i/КафедраСокращенноеНазвание/text() }</b> )
       else( <a href = "{ $href }">{ $i/КафедраСокращенноеНазвание/text() }</a> )
   let $все :=
     if( $deps = 'all' )
     then( <b>Все</b> )
     else(
       <a href = "{ $baseURL }">Все</a>
     )    
   let $результат :=
      <div>
          <h2>Дисциплины кафедр(ы) { $кафедра } по РУПам { string-join( sort( $years ), ', ' )} годов приёма</h2>
          <p>Кафедры: { $все } { $списокКафедр }</p>
          <p>Дисциплины: <a href = "?mode=all">все</a> <a href = "?mode=0">незагруженные</a> <a href = "?host=0">"сироты"</a></p>
          <ol>Всего: { $countTotal }, в т.ч. уникальных { count( $list ) }: { $items }</ol>  
      </div>
  let $tpl := doc( "html/main.tpl.html" )
  return
    $tpl update insert node $результат into .//body   
   
     
};

declare function ivgpu:дисциплины( $path as xs:string ) as element( record )* {
  csv:parse(  
      fetch:text(
        $path 
    ), map{ 'header' : true() } )/csv/record
};