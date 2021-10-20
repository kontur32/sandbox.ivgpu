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
  %rest:path( '/sandbox/ivgpu/statistic/lists/subjects/{ $текущаяКафедра }/{ $текущийПреподаватель }' )
  %rest:query-param( 'year', '{ $year }', '2017,2018,2019,2020,2021' )
  %output:method( 'xhtml' )
function ivgpu:view( $текущаяКафедра, $year, $текущийПреподаватель ){
   
   let $кафедры :=
     data:getResourceCSV( config:param( 'ресурс.кафедры' ) )/csv/record
   
   let $кафедра :=
     $кафедры[ КафедраКод =  $текущаяКафедра ]
     /КафедраСокращенноеНазвание/text()

   let $дисциплины :=
     if( $кафедры[ КафедраКод = $текущаяКафедра ]/Дисциплины/text() )
     then(
       data:getResourceCSV( $кафедры[ КафедраКод = $текущаяКафедра ]/Дисциплины/text() )
       /csv/record
     )
     else()

   let $fileContentList :=
    rup:getFileContentList( '46686' )
    /NAME/
    normalize-space( substring-before( text(), '_содержание.docx' ) )
   
   let $years := tokenize( $year, ',' )
   let $дисциплиныПоРУПам := 
     data:getProgrammData()
     [ @Год = $years ]
     /Дисциплины/Дисциплина[ @КодКафедры = $текущаяКафедра ]

   let $названияДисциплин := distinct-values( $дисциплиныПоРУПам/@Название/data() )
   let $countTotal := count( $названияДисциплин )
   
   let $списокДисциплин := 
     for $i in $названияДисциплин
     return
       [ $i, count( $дисциплиныПоРУПам[ @Название = $i ] ) ]
   
   let $items :=    
     for $дисциплина in $списокДисциплин
     order by $дисциплина?2 descending
     let $содержаниеЗагружено := replace( $дисциплина?1, ':', '_' ) = $fileContentList
     let $заполнена := 
       if( $содержаниеЗагружено  )
       then( [ 'содержание загружено', 'font-weight: bold;' ] )
       else( [ 'содержание не загружено', 'font-weight: normal;' ] )

     let $ссылка := 
       if( not( $содержаниеЗагружено ) )
       then(
         let $href := '/sandbox/ivgpu/generate/Аннотация/' || $дисциплина?1 || '/шаблон.содержания'
         return
           <span> : <a href = "{ $href }">скачать шаблон содержания</a></span>
       )
       else()
     
     let $ссылкаРУПыПоДисциплине := 
       '/sandbox/ivgpu/statistic/lists/subjects/' || $дисциплина?1 || '/directions'
     
     let $преподаватель :=
       $дисциплины
       [ Дисциплина = $дисциплина?1 ]
       /Преподаватель/text()
     
     where $преподаватель = $текущийПреподаватель
     
     let $направления :=
       let $направленияПреподавателя := 
         $дисциплины
         [ Дисциплина = $дисциплина?1 ]
         [ Преподаватель = $текущийПреподаватель ]
         /Код_направления/tokenize( replace( text(), '\s', '' ), ',' )
         
       let $направленияДругихПреподавателей :=
         distinct-values(
           $дисциплины
           [ Дисциплина = $дисциплина?1 ]
           [ Преподаватель != $текущийПреподаватель ]
           /Направление/tokenize( replace( text(), '\s', '' ), ',' )
         )
       return
         if( count( $направленияПреподавателя ) )
         then( $направленияПреподавателя )
         else(
          let $всеНаправления :=
            $дисциплиныПоРУПам[ @Название = $дисциплина?1 ]
            /parent::*/parent::*
            /@КодНаправления/data()
          return
            distinct-values( $всеНаправления[ not( . = $направленияДругихПреподавателей ) ] )
         )
     
     let $ссылкиНаСтраницыНаправлений :=
       for $i in $направления
       order by $i
       let $href := '/sandbox/ivgpu/directions/' || $i
       return
         <a href = '{ $href }'>{ $i }</a>
     return
       <li style = "{ $заполнена?2 }"><a href = "{ $ссылкаРУПыПоДисциплине }">{ $дисциплина?1 }</a> : (направления: { $ссылкиНаСтраницыНаправлений }) { $заполнена?1 }{ $ссылка }</li>
    
   let $результат := 
      <div>
          <h2>Дисциплины преподавателя</h2>
          <div>
            <p><b>Преподаватель: </b>{ $текущийПреподаватель}</p>
            <p><b>Кафедра: </b>{ $кафедра }</p>
            <p><b>Годы приема: </b> { string-join( sort( $years ), ', ' )}</p>
          </div>
          <ol>{ $items }</ol>  
      </div>
  let $tpl := doc( "html/main.tpl.html" )
  return
    $tpl update insert node $результат into .//body   
};
  