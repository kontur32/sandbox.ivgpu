module namespace ivgpu = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/загрузкаРПД';

import module namespace
  config = '/sandbox/ivgpu/api/v01/generate/config'
    at '../config.xqm';
  
import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at '../generate.data.xqm';
import module namespace 
  check = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/проверкаНаличияРПД'
    at '../RPD/generate.RPD.check.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/check/subjects/{ $dep }' )
  %rest:method( 'GET' )
function ivgpu:идентификаторПапкиРПД( $dep ){        
  let $программы := data:getProgrammData()[ position() < 30 ]
  let $дисциплины :=       
    for $i in $программы
    for $j in $i/Дисциплины/Дисциплина[ @КодКафедры = $dep ]
    let $кодДисциплины := $j/@КодДисциплины/data()
    let $наличие := check:check( $i, $кодДисциплины )
    let $названиеДисциплины := $j/@Название/data()
    order by $названиеДисциплины
    where not( $наличие/item )  
    group by $названиеДисциплины
    return
      <record название = "{ $названиеДисциплины }" количество = "{ count( $i ) }">{  
          for $p in $i
          return
            <программа>{ $p/Файл/@ID/data() }</программа>
      }</record>
   return
     <csv>{ $дисциплины }</csv>
};