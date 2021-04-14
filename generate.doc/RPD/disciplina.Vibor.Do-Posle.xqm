module namespace ivgpu = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/данныеДисциплины';

import module namespace request = 'http://exquery.org/ns/request';
import module namespace data = '/sandbox/ivgpu/generate/data'
  at '../../generate.doc/generate.data.xqm';

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
  
  let $dd := db:open( 'tmp-simplex', 'выбор' )
    /выбор/Дисциплина
  let $db:=
    if( $dd[ @ID = $id and @КодДисциплины = $disc ] )
    then(
      $dd[ @ID = $id and @КодДисциплины = $disc ] 
    )
    else(
      $dd[ @Название = $дисциплина/@Название/data() ]
    )

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
    let $семестр := $дисциплина//семестр[ 1 ]/number()
    for $i in $дисциплины
    where $i//семестр[ 1 ]/number() > $семестр or  $i/@Семестр/data() = ""
    where not( $i/@КодДисциплины[ contains( data(), '.ДВ.' ) or contains( data(), 'ФТД.' ) ] )
    return
      <li>
        {
          element {'input'} {
            attribute {'form'} {'disc'},
            attribute {'type'} {'checkbox'},
            attribute {'name'} { "после--" || $i/@КодДисциплины/data() },
            if( $i/@Название = $db/ДисциплиныПосле/Дисциплина/@Название )
            then( attribute { 'checked' } { 'yes' } )
            else()
          }
        }
        { $i/@КодДисциплины/data() } - { $i/@Название/data() }
      </li>
  
  let $дисциплиныДо :=
    let $семестр := $дисциплина//семестр[ 1 ]/number()
    for $i in $дисциплины
    where $i//семестр[ 1 ]/number() <= $семестр
    where not( $i/@КодДисциплины[ contains( data(), '.ДВ.' ) or contains( data(), 'ФТД.' ) ] )
    return
      <li>
        {
          element {'input'} {
            attribute {'form'} {'disc'},
            attribute {'type'} {'checkbox'},
            attribute {'name'} { "до--" || $i/@КодДисциплины/data() },
            if( $i/@Название = $db/ДисциплиныДо/Дисциплина/@Название )
            then( attribute { 'checked' } { 'yes' } )
            else()
          }
        }
         { $i/@КодДисциплины/data() } - { $i/@Название/data() }
      </li>
  
  let $hrefРПД := 
         "/sandbox/ivgpu/api/v01/generate/РПД.Титул/" || 
         $id || "/" || $disc || '?mode=dev'
  let $hrefТилулРПД := 
         "/sandbox/ivgpu/api/v01/generate/РПД.Титул/" || 
         $id || "/" || $disc
  let $hrefA := 
         "/sandbox/ivgpu/generate/Аннотация/" || 
         $id || "/" || $disc || "?mode=s"
  
  let $result :=
     <div style = "padding-inline-start : 40px">
       <div>
         <h1>{ $дисциплина/@Название/data() }</h1>
         <span>{ $дисциплина/@КодДисциплины/data() }</span>
       </div>
       <ul>
         <b>Формы контроля: </b>
         {
           for $i in $дисциплина/@ФормыКонтроля/tokenize( data(), ',' )
           return
             <li>{ $i }</li>
         }
       </ul>
       <ul><b>Компенетции:</b>{
         for $i in $дисциплина/Компетенции/Компетенция
         return
           <li>{ $i/@ШифрКомпетенции/data() } : { $i/@Название/data() }</li>
       }</ul>
       <ul><b>Виды работ:</b>{ $видыРабот }</ul>
       <input form = 'disc' type="submit" value = "Сохранить выбор дисцилин" formaction = "/sandbox/ivgpu/api/v01/programms/{ $id }/{ $дисциплина/@КодДисциплины/data() }/comp" formmethod = "post"/>
       <a href = "{ $hrefРПД }"><button>Скачать РПД</button></a>
       <a href = "{ $hrefТилулРПД }"><button>Скачать только титул РПД</button></a>
       <a href = "{ $hrefA }"><button>Скачать аннотацию</button></a>
       <table valign="top">
         <tr>
           <td><b>Дисциплины "до":</b></td>
           <td><b>Дисциплины "после":</b></td>
         </tr>
         <tr valign="top">
           <td>{ $дисциплиныДо }</td>
           <td>{ $дисциплиныПосле }</td>
         </tr>
       </table>
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