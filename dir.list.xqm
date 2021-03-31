module namespace ivgpu = 'oop.List';

import module namespace request = 'http://exquery.org/ns/request';
import module namespace functx = "http://www.functx.com";

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
  at 'generate.doc/generate.data.xqm';

import module namespace 
  rup = 'subjects.Department.Direction' 
    at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';
    
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
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$ID}/{$form}/аннотации' )
  %output:method( 'xhtml' )
function ivgpu:аннотации( $year, $dir, $ID, $form ){
  let $fileContentList :=
    rup:getFileContentList( '46686' )
    /NAME/
    functx:replace-multi( normalize-space( substring-before( text(), '_' ) ), ':', '_' )
  
  let $План := 
      data:getProgrammData()
      [ @Год/data() = $year ]
      [ @КодНаправления/data() = $dir ]
      [ Файл/@ID/data() = $ID ]
      [ @ФормаОбучения/data() = $form ]
  let $b := $План//Дисциплина

  let $дисциплины :=
    <table>
       <tr>
          <th>Код</th>
          <th>Название</th>
          <th>Код кафедры</th>
          <th>ЗЕТ</th>
          <th>Аннотация</th>
       </tr>
      {
        for $i in $b
        let $естьКонтент := 
          functx:replace-multi(
            $i/@Название/data() , ( ':', ',' ), ( '-', '.' )
          ) = $fileContentList
        
        let $hrefA := 
         "/sandbox/ivgpu/generate/Аннотация/" || 
         $План/Файл/@ID || "/" || $i/@КодДисциплины || "/pdf"
        return
           <tr>
              <td>{ $i/@КодДисциплины/data() }</td>
              <td>{ $i/@Название/data() }</td>
              <td align="center">{ $i/@КодКафедры/data() }</td>
              <td align="center">{ $i/@ЗЕТ/data() }</td>
              {
                if( $естьКонтент )
                then(
                  <td align="center">
                    <a href = "{ $hrefA }">скачать</a>
                  </td>
                )
                else()
              }
           </tr>
      }
    </table>
  return
    <div>
      <table>
        <tr>
          <th align="left">Код направления</th>
          <td>{$dir}</td>
        </tr >
        <tr>
          <th align="left">Название направления</th>
          <td>{$План/@НазваниеНаправления/data()}</td>
        </tr>
        <tr>
          <th align="left">Название ООП</th>
          <td>{$План/@НазваниеПрофиля/data()}</td>
        </tr>
        <tr>
          <th align="left">Форма обучения</th>
          <td>{$form}</td>
        </tr>
        <tr>
          <th align="left">Год приема</th>
          <td>{$year}</td>
        </tr>
        <tr>
          <th align="left">Выпускающая кафедра</th>
          <td>{ $План/@Кафедра/data() }</td>
        </tr>
      </table>
      <hr/>
      {
        $дисциплины
      }
    </div>
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

(: старый вариант - на удаление :)
declare 
  %rest:path( '/sandbox/ivgpu/api/directions/{$year}/{$dir}/{$oop}/{$form}/{$disc}/comp' )
function ivgpu:компетенции( $year, $dir, $oop, $form, $disc ){
  let $дисциплина := 
      data:getProgrammData()
      [ @Год/data() = $year ]
      [ @КодНаправления/data() = $dir ]
      [ @НазваниеПрофиля/data() = $oop ]
      [ @ФормаОбучения/data() = $form ][ 1 ]
      //Дисциплина[ @КодДисциплины/data() = $disc ]
  
  let $видыРабот := 
    for $i in $дисциплина/видыРабот/видРабот
    let $семестр := $i/семестр/text()
    group by $семестр
    return
      <видыРабот семестр = "{ $семестр }">
        {
        for $j in $i
        where $j/кодВидаРабот/text() = ( '101', '102', '103', '104', '105', '107','108', '109', '141', '1000')
        return 
            $j/названиеВидаРабота/text() || ':' || $j/часы/text()
        }
      </видыРабот>
  return
     <Дисциплина>
       { $дисциплина/@Название }
       { $дисциплина/@КодДисциплины }
       { $дисциплина/@ФормыКонтроля }
       { $дисциплина/Компетенции }
       { $видыРабот }
     </Дисциплина>
};

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/programms/{ $id }/{ $disc }/comp' )
  %rest:method('GET')
  %output:method( 'xhtml' )
function ivgpu:компетенции( $id, $disc ){
  let $видыРабот := ( '101', '102', '103', '104', '105', '107','108', '109', '141', '1000')
  
  let $дисциплины := 
      data:getProgrammData()
      [ Файл/@ID = $id ]
      /Дисциплины/Дисциплина
  
  let $дисциплина := $дисциплины[ @КодДисциплины/data() = $disc ]
  
  let $db:=
    db:open( 'tmp-simplex', 'выбор' )
    /выбор/Дисциплина[ @ID = $id and @КодДисциплины = $disc ]
  
  let $видыРабот := 
    for $i in $дисциплина/видыРабот/видРабот
    let $семестр := $i/семестр/text()
    group by $семестр
    return
      <li><span>{ $семестр } семестр: </span>
        {
        for $j in $i
        where $j/кодВидаРабот/text() = $видыРабот
        return 
          $j/названиеВидаРабота/text() || ':' || $j/часы/text()
        }
      </li>

  let $дисциплиныПосле :=
    let $семестр := $дисциплина/@Семестр/tokenize( data(), ',' )
    for $i in $дисциплины[ @Семестр/tokenize( data(), ',' ) >= $семестр ]
    where not( $i/@КодДисциплины[ contains( data(), '.ДВ.' ) or contains( data(), 'ФТД.' ) ] )
    return
      <li>
        {
          element {'input'} {
            attribute {'form'} {'disc'},
            attribute {'type'} {'checkbox'},
            attribute {'name'} { "после--" || $i/@КодДисциплины/data() },
            if( $i/@КодДисциплины = $db/ДисциплиныПосле/Дисциплина/@КодДисциплины )
            then( attribute { 'checked' } { 'yes' } )
            else()
          }
        }
        { $i/@КодДисциплины/data() } - { $i/@Название/data() }
      </li>
  
  let $дисциплиныДо :=
    let $семестр := $дисциплина/@Семестр/tokenize( data(), ',' )
    for $i in $дисциплины[ @Семестр/tokenize( data(), ',' ) <= $семестр ]
    where not( $i/@КодДисциплины[ contains( data(), '.ДВ.' ) or contains( data(), 'ФТД.' ) ] )
    return
      <li>
        {
          element {'input'} {
            attribute {'form'} {'disc'},
            attribute {'type'} {'checkbox'},
            attribute {'name'} { "до--" || $i/@КодДисциплины/data() },
            if( $i/@КодДисциплины = $db/ДисциплиныДо/Дисциплина/@КодДисциплины )
            then( attribute { 'checked' } { 'yes' } )
            else()
          }
        }
         { $i/@КодДисциплины/data() } - { $i/@Название/data() }
      </li>
  
  let $result :=
     <div>
       <p>Название: { $дисциплина/@Название/data() }</p>
       <p>Код: { $дисциплина/@КодДисциплины/data() }</p>
       <p>Формы контроля: { $дисциплина/@ФормыКонтроля/data() }</p>
       <ul><b>Компенетции:</b>{
         for $i in $дисциплина/Компетенции/Компетенция
         return
           <li>{ $i/@ШифрКомпетенции/data() } : { $i/@Название/data() }</li>
       }</ul>
       <ul><b>Виды работ:</b>{ $видыРабот }</ul>
       <ul><b>Дисциплины "до":</b>{ $дисциплиныДо }</ul>
       <ul><b>Дисциплины "после":</b>{ $дисциплиныПосле }</ul>
       <input form = 'disc' type="submit" value = "Отправить" formaction = "/sandbox/ivgpu/api/v01/programms/{ $id }/{ $дисциплина/@КодДисциплины/data() }/comp" formmethod = "post"/>
       <input form = "disc" type = 'hidden' name = 'redirect' value = "{request:scheme() || '://' || request:hostname() ||':' ||  request:port() }/sandbox/ivgpu/api/v01/programms"/>
       <form id = "disc"/>
     </div>
  return
     $result 
};

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/programms/{ $id }/{ $disc }/comp' )
  %rest:method('POST')
  %updating
function ivgpu:компетенции-save( $id, $disc ){
  let $дисциплины := 
      data:getProgrammData()
      [ Файл/@ID = $id ]
      /Дисциплины/Дисциплина
  
  let $дисциплина := $дисциплины[ @КодДисциплины/data() = $disc ]
  
  let $db:=
    db:open( 'tmp-simplex', 'выбор' )/выбор
  
  let $параметры :=
    <Дисциплина ID = "{ $id }" КодДисциплины = "{ $disc }" Название = "{ $дисциплина/@Название/data() }">
      <ДисциплиныДо>{
        for $i in request:parameter-names()
        where starts-with( $i, 'до--' )
        return
          <Дисциплина КодДисциплины = "{ substring-after( $i, '--' ) }" Название = "{ $дисциплины[ @КодДисциплины/data() = substring-after( $i, '--' ) ]/@Название/data() }"/>
      }
      </ДисциплиныДо>
      <ДисциплиныПосле>{
        for $i in request:parameter-names()
        where starts-with( $i, 'после--' )
        return
          <Дисциплина КодДисциплины = "{ substring-after( $i, '--' ) }" Название = "{ $дисциплины[ @КодДисциплины/data() = substring-after( $i, '--' ) ]/@Название/data() }"/>
      }
      </ДисциплиныПосле>
    </Дисциплина>
  return
    if( count( request:parameter-names() ) > 0 )
    then(
        if( $db/Дисциплина[ @ID = $id and @КодДисциплины = $disc ] )
        then( replace node $db/Дисциплина[ @ID = $id and @КодДисциплины = $disc ] with $параметры )
        else( insert node $параметры into $db )
    )
    else( ),
    let $redirect :=
      string-join(
        (
          request:parameter( 'redirect' ),
          $id,
          encode-for-uri( $disc ) ,
          'comp'
        ),
        '/'
      )
     return
       update:output( web:redirect( $redirect ) )
};