module namespace ivgpu = 'subjects.Departments.List';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at 'generate.doc/generate.data.xqm';

import module namespace 
  rup = 'subjects.Department.Direction' 
    at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/statistic/lists/subjects/{ $текущаяКафедра }/{ $текущийПреподаватель }' )
  %rest:query-param( 'year', '{ $year }', '2016,2017,2018,2019,2020' )
  %output:method( 'xhtml' )
function ivgpu:view( $текущаяКафедра, $year, $текущийПреподаватель ){
   let $кафедры := 
     ivgpu:дисциплины(
       'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=183523999&amp;single=true&amp;output=csv'
     )

   let $кафедра :=
     $кафедры[ КафедраКод =  $текущаяКафедра ]
     /КафедраСокращенноеНазвание/text()

   let $дисциплины :=
     if( $кафедры[ КафедраКод = $текущаяКафедра ]/Дисциплины/text() )
     then(
       ivgpu:дисциплины( $кафедры[ КафедраКод = $текущаяКафедра ]/Дисциплины/text() )
     )
     else()

   let $fileContentList :=
    rup:getFileContentList( '46686' )
    /NAME/
    replace( normalize-space( substring-before( text(), '_' ) ), ':', '_' )
   
   let $years := tokenize( $year, ',')
   let $дисциплиныПоРУПам := 
     data:getProgrammData()
     //Дисциплина[ @КодКафедры = $текущаяКафедра ]
     [ parent::*/parent::* [ @Год = $years ] ]
     
   let $названияДисциплин := distinct-values( $дисциплиныПоРУПам/@Название/data() )
   let $countTotal := count( $названияДисциплин )
   
   let $списокДисциплин := 
     for $i in $названияДисциплин
     return
       [ $i, count( $дисциплиныПоРУПам[ @Название = $i ] ) ]
   
   let $items :=    
     for $дисциплина in $списокДисциплин
     order by $дисциплина?2 descending
     let $заполнена := 
       if( $дисциплина?1 = $fileContentList  )
       then( [ 'содержание загружено', 'font-weight: bold;' ] )
       else( [ 'содержание не загружено', 'font-weight: normal;' ] )

     let $ссылка := 
       if( not( $дисциплина?1 = $fileContentList ) )
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
         /Направление/tokenize( replace( text(), '\s', '' ), ',' )
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
          <h2>Дисциплины кафедр(ы) { $кафедра } по РУПам { string-join( sort( $years ), ', ' )} годов приёма</h2>
          <ol>{ $items }</ol>  
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
  