module namespace ivgpu = 'oop.List';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/directions' )
  %rest:query-param( 'year', '{ $yearsList }' )
  %rest:query-param( 'dep', '{ $dep }' )
  %output:method( 'xhtml' )
function ivgpu:view( $yearsList, $dep ){
  let $b := 
    data:getProgrammData()
    [ if( $dep )then( @Кафедра = tokenize( $dep, ',' ) )else( true() ) ]
  
  let $years := 
    if( $yearsList )
    then(
      tokenize( $yearsList, ',' )
    )
    else(
      distinct-values( $b/@Год/data() )[. != '' ]
    )
    
  let $list :=
    function( $year ){
    let $oop := $b[ @Год = $year ]
    let $oopKod := distinct-values( $oop/@КодНаправления/data() )
    for $i in $oopKod
    where $i
    order by $i
    let $dep := sort( distinct-values( $oop[@КодНаправления = $i ]/@Кафедра/number( . ) ) )
    return
      <li>{ $i } : <a href = '{ "/sandbox/ivgpu/directions/" || $i }'>{ normalize-space( $oop[@КодНаправления = $i ][1]/@НазваниеНаправления/data() ) }</a>; кафедра(ы): { string-join( $dep, ', ' ) }</li>
    }
  return
   <html>
     <body>
       <h2>Направления подготовки за { string-join( sort( $years ), ', ') } год(ы)</h2>
       {
         for $y in $years
         order by number( $y )
         return
           <ol><h3>{ $y }</h3>{ $list( $y ) }</ol>
       }
     </body>
   </html>
};

declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}' )
  %output:method( 'csv' )
  %output:csv ("header=yes, separator=semicolon")
function ivgpu:dir( $year){
  let $b := 
    data:getProgrammData()[ @Год/data() = $year ]

return
  <csv>
    {
      for $i in distinct-values( $b /@КодНаправления/data() )
      order by $i
      return
         <record>
            <Код>{$i}</Код>
            <НазваниеНаправления>{ $b[ @КодНаправления = $i ][1]/@НазваниеНаправления/data()}</НазваниеНаправления>
         </record>
    }
  </csv>  

};

declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}' )
  %output:csv ("header=yes, separator=semicolon")
  %output:method( 'csv' )
function ivgpu:oop( $year, $dir ){
  let $b := 

      data:getProgrammData()
      [ @Год/data() = $year ]
      [ @КодНаправления/data() = $dir ]
      

return
  <csv>
    {
      for $i in $b
      return
         <record>
            <НазваниеПрофиля>{$i/@НазваниеПрофиля/data()}</НазваниеПрофиля>
            <ФормаОбучения>{$i/@ФормаОбучения/data() }</ФормаОбучения>
         </record>
    }
  </csv>  
};

declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$oop}/{$form}' )
  %output:method( 'csv' )
  %output:csv ("header=yes, separator=semicolon")
function ivgpu:disc( $year, $dir, $oop, $form ){
  let $b := 
      data:getProgrammData()
      [ @Год/data() = $year ]
      [ @КодНаправления/data() = $dir ]
      [ @НазваниеПрофиля/data() = $oop ]
      [ @ФормаОбучения/data() = $form ]
      //Дисциплина

return
  <csv>
    {
      for $i in $b
      return
         <record>
            <КодДисциплины>{$i/@КодДисциплины/data() }</КодДисциплины>
            <НазваниеДисциплины>{ $i/@Название/data() }</НазваниеДисциплины>
            <КодКафедры>{$i/@КодКафедры/data() }</КодКафедры>
            <ЗЕТ>{$i/@ЗЕТ/data() }</ЗЕТ>
         </record>
    }
  </csv>  
};

declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$oop}/{$form}/{$disc}' )
  %output:method( 'csv' )
  %output:csv ("header=yes, separator=semicolon")
function ivgpu:control( $year, $dir, $oop, $form, $disc ){
  let $b := 
      data:getProgrammData()
      [ @Год/data() = $year ]
      [ @КодНаправления/data() = $dir ]
      [ @НазваниеПрофиля/data() = $oop ]
      [ @ФормаОбучения/data() = $form ]
      //Дисциплина[ @КодДисциплины/data() = $disc ]
      
let $sem := tokenize( $b/@Семестр/data(), ',' )
let $control := tokenize( $b/@ФормыКонтроля/data(), ',' )
return
  <csv>
    {
      for $i in 1 to count( $sem )
      return
         <record>
            <Семестр>{ $sem[$i] }</Семестр>
            <ФормыКонтроля>{ $control[$i] }</ФормыКонтроля>
         </record>
    }
  </csv>  
};

declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$oop}/{$form}/{$disc}/comp' )
function ivgpu:компетенции( $year, $dir, $oop, $form, $disc ){
  let $дисциплина := 
      data:getProgrammData()
      [ @Год/data() = $year ]
      [ @КодНаправления/data() = $dir ]
      [ @НазваниеПрофиля/data() = $oop ]
      [ @ФормаОбучения/data() = $form ]
      //Дисциплина[ @КодДисциплины/data() = $disc ]
      
return
   <Дисциплина>
     { $дисциплина/@Название }
     { $дисциплина/@КодДисциплины }
     { $дисциплина/Компетенции }
   </Дисциплина>
    
};