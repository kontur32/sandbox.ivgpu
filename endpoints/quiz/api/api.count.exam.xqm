module namespace ivgpu.count = 'sandbox/ivgpu/api/jwt/validate';

import module namespace данные = 'sandbox/ivgpu/вопросник/модули/данные'
  at '../modules/modules.data.xqm';

import module namespace dateTime = 'dateTime' at 'http://iro37.ru/res/repo/dateTime.xqm';

declare
  %rest:path('/sandbox/ivgpu/api/v01/exams/count')
  %output:method('json')
function ivgpu.count:main(){
  let $data := данные:получитьзадолженность()
  
  let $tt := 
    for $i in $data[ cell[ @label = "Дата ликвидации" ] != "" ]
    let $d :=
      dateTime:dateParse( replace( $i/cell[ @label = "Дата ликвидации" ]/text(), '\.0$', '') )
    
    order by $d
    group by $d
    
    return
      [ count( $i ),  $d ]
  
  return
    <json type = 'array'>
      
        <_ type ='array'>
          <_ type = 'string'>2020-11-02</_>
          <_ type = 'number'>1010</_>
          <_ type = 'number'>0</_>
        </_>
     
      {
        
        for $i in 1 to count( $tt )
        let $current := $tt[ position() <= $i ]
        return
           <_ type = 'array'>
            <_ type = 'string'>{ xs:string( $tt[ $i ]?2 ) }</_>
            <_ type = 'number'>1010</_>
            <_ type = 'number'>{ sum( $current?1 ) }</_>
          </_>
      }
    </json>
};