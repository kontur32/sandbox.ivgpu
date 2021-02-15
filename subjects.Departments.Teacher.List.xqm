module namespace ivgpu = 'subjects.Departments.List';

import module namespace functx = "http://www.functx.com";
import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at 'generate.doc/generate.data.xqm';
import module namespace 
  rup = 'subjects.Department.Direction' 
    at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/statistic/lists/subjects/{ $id }/{ $teacher }' )
  %rest:query-param( 'year', '{ $year }', '2016,2017,2018,2019,2020' )
  %output:method( 'xhtml' )
function ivgpu:view( $id, $year, $teacher ){
   let $кафедры := 
    csv:parse(  
      fetch:text(
        'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=183523999&amp;single=true&amp;output=csv'
    ), map{ 'header' : true() } )/csv/record

   let $кафедра := $кафедры[ КафедраКод =  $id ]/КафедраСокращенноеНазвание/text()

   let $дисциплины :=
     if( $кафедры[ КафедраКод = $id ]/Дисциплины/text() )
     then(
       ivgpu:дисциплины( $кафедры[ КафедраКод = $id ]/Дисциплины/text() )
     )
     else()
   
   
   let $fileContentList :=
    rup:getFileContentList( '46686' )
    /NAME/
    functx:replace-multi( normalize-space( substring-before( text(), '_' ) ), ':', '_' )
   
   let $years := tokenize( $year, ',')
   let $dep := tokenize( $id, ',')
   let $d := 
     data:getProgrammData()
     //Дисциплина[ @КодКафедры = $dep ]
     [ parent::*/parent::* [ @Год = $years ] ]
     
   let $list := distinct-values( $d /@Название/data() )
   let $countTotal := count( $d )
   let $m := 
     for $i in $list
     return
       [ $i, count( $d[ @Название = $i ] ) ]
    let $items :=    
     for $i in $m
     order by $i?2 descending
     let $заполнена := 
       if( $i?1 = $fileContentList  )
       then( [ 'загружена', 'font-weight: bold;' ] )
       else( [ 'не загружена', 'font-weight: normal;' ] )
     
     let $преподаватель := $дисциплины[ Дисцилина = $i?1 ][1]/Преподаватель/text()
     let $ссылка := 
       if( not( $i?1 = $fileContentList ) )
       then(
         let $href := '/sandbox/ivgpu/generate/Аннотация/' || $i?1 || '/шаблон.содержания'
         return
           <a href = "{ $href }">скачать шаблон содержания</a>
       )
       else()
     let $ссылкаРУПыПоДисциплине := 
       '/sandbox/ivgpu/statistic/lists/subjects/' || $i?1 || '/directions'
     where $преподаватель = $teacher
     return
     <li style = "{ $заполнена?2 }"><a href = "{ $ссылкаРУПыПоДисциплине }">{ $i?1 }</a>{ ' : ' || $i?2 || ' : ' || $заполнена?1  || ' : '}{ $ссылка }</li>
    return
      <html>
        <body>
          <h2>Дисциплины кафедр(ы) { $кафедра } по РУПам { string-join( sort( $years ), ', ' )} годов приёма</h2>
          <ol>Всего: { $countTotal }, в т.ч. уникальных { count( $list ) }: { $items }</ol>  
        </body>
      </html>
};

declare function ivgpu:дисциплины( $path as xs:string ) as element( record )* {
  csv:parse(  
      fetch:text(
        $path 
    ), map{ 'header' : true() } )/csv/record
};
  