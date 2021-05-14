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
  %rest:query-param( 'year', '{ $year }', '2016,2017,2018,2019,2020' )
  %output:method( 'xhtml' )
function ivgpu:view( $id, $year ){
    
   let $кафедры :=
     data:getResourceCSV( config:param( 'ресурс.кафедры' ) )/csv/record
   
   let $кафедра := $кафедры[ КафедраКод =  $id ]/КафедраСокращенноеНазвание/text()

   let $дисциплины :=
     if( $кафедры[ КафедраКод = $id ]/Дисциплины/text() )
     then(
       data:getResourceCSV( $кафедры[ КафедраКод = $id ]/Дисциплины/text() )
       /csv/record
     )
     else()
   
   
   let $fileContentList :=
    rup:getFileContentList( '46686' )
    /NAME/
    replace( normalize-space( substring-before( text(), '_' ) ), ':', '_' )
   
   let $years := tokenize( $year, ',' )
   let $dep := tokenize( $id, ',' )
   let $программы := 
     data:getProgrammData()
     [ @Год = $years ]
     /Дисциплины/Дисциплина[ @КодКафедры = $dep ]
     
   let $list := distinct-values( $программы/@Название/data() )
   let $countTotal := count( $программы )
   let $программыКоличество := 
     for $i in $list
     return
       [ $i, count( $программы[ @Название = $i ] ) ]
   
   let $items :=    
     for $i in $программыКоличество
     order by $i?2 descending
     let $заполнена := 
       if( $i?1 = $fileContentList  )
       then( [ 'загружена', 'font-weight: bold;' ] )
       else( [ 'не загружена', 'font-weight: normal;' ] )
     let $преподаватели := 
       for $преподаватель in $дисциплины[ Дисциплина = $i?1 ]/Преподаватель/text()
       let $href := '/sandbox/ivgpu/statistic/lists/subjects/' || $id || '/' || $преподаватель
       return
         <a href = "{ $href }"> { $преподаватель }</a>
     
     let $href2 :=
       '/sandbox/ivgpu/statistic/lists/subjects/' || $i?1 || '/directions'
     return
       <li style = "{ $заполнена?2 }">
         <a href = "{ $href2 }">{ $i?1 }</a>
         { ' : ' || $i?2 || ' : ' || $заполнена?1 || ' : '}{ $преподаватели }
       </li>
    
   let $результат :=
      <div>
          <h2>Дисциплины кафедр(ы) { $кафедра } по РУПам { string-join( sort( $years ), ', ' )} годов приёма</h2>
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