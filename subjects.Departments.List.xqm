module namespace ivgpu = 'subjects.Departments.List';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';


declare 
  %rest:path( '/sandbox/ivgpu/subjects.Departments.List' )
  %rest:query-param( 'id', '{ $id }', '29' )
  %rest:query-param( 'year', '{ $year }', '2019' )
  %output:method( 'xhtml' )
function ivgpu:view( $id, $year ){
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
       [ $i, count($d[ @Название = $i ] ) ]
  let $items :=    
   for $i in $m
   order by $i?2 descending
   return
   <li>{$i?1 || ' : ' || $i?2 || ': '  }</li>
  return
    <html>
      <body>
        <h2>Дисциплины кафедр(ы) { $id } за период: { sort( $years ) }</h2>
        <ol>Всего: { $countTotal } { $items }</ol>  
      </body>
    </html>
       
     
};