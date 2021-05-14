module namespace ivgpu = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/данныеДисциплины';

import module namespace request = 'http://exquery.org/ns/request';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../config.xqm';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at '../../generate.doc/generate.data.xqm';

import module namespace 
  check = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/проверкаНаличияРПД'
    at 'generate.RPD.check.xqm';

import module namespace 
  rup = 'subjects.Department.Direction' 
    at '../../tmp-ivgpu-discipliny-po-rupam-WEB.xqm';
    
(:
  запись выбора дисцилпин "до" и "после"
:)

declare 
  %rest:path( '/sandbox/ivgpu/api/v01/programms/{ $id }/{ $disc }/comp' )
  %rest:method('GET')
  %rest:query-param( 'message', '{ $message }', '' )
  %output:method( 'xhtml' )
function ivgpu:компетенции( $id, $disc, $message ){
  
  let $fileContentList :=
    rup:getFileContentList( '46686' )
    /NAME/
    replace( normalize-space( substring-before( text(), '_' ) ), ':', '' )
  
  let $видыРабот := ( '101', '102', '103', '104', '105', '107','108', '109', '141', '1000' )
  let $программа :=  data:getProgrammData( $id )
  let $дисциплины := $программа/Дисциплины/Дисциплина
  
  let $дисциплина := $дисциплины[ @КодДисциплины/data() = $disc ]
  
  let $checkRoot :=
    check:check( $программа, $дисциплина/@КодДисциплины/data(), config:param( 'upload.Directory.Root' ) )/item
  let $checkSecondary :=
    check:check( $программа, $дисциплина/@КодДисциплины/data(), config:param( 'upload.Directory.Secondary' ) )/item
  
  let $базыДляЗагрузки := 
   (
     config:param( 'upload.Directory.Root.Alias' ),
     config:param( 'upload.Directory.Secondary.Alias' )
   )
    
  let $dd := db:open( 'tmp-simplex', 'выбор' )/выбор/Дисциплина
  
  let $db:=
    if( $dd[ @ID = $id and @КодДисциплины = $disc ] )
    then( $dd[ @ID = $id and @КодДисциплины = $disc ] )
    else( $dd[ @Название = $дисциплина/@Название/data() ] )

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
         $id || "/" || $disc 
  
  let $result :=
     <div style = "padding-inline-start : 40px">
       <div>
         <h1>
           { $дисциплина/@Название/data() }
         </h1>
         <span>
           Шифр: <b>{ $дисциплина/@КодДисциплины/data() }</b>,
           Направление: <b>{ $программа/@КодНаправления/data() }</b>,
           Профиль: <b>{ $программа/@НазваниеПрофиля/data() }</b>,
           Год приема: <b>{ $программа/@Год/data() }</b>,
           Форма обучения: <b>{ $программа/@ФормаОбучения/data() }</b>
         </span>
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
       
       <div>
         <ul><b>Статус загрузки: </b>
         <li>В базу "{ $базыДляЗагрузки[ 1 ] }"
         {
           if( $checkRoot )
             then(
                 <span  class = 'text-success'>
                   файл загружен:   
                     (<a href = "{ $checkRoot/DOWNLOAD_URL/text()}">скачать</a>)
                 </span>
               )
             else( <span class = 'text-danger'>файл еще не загружен</span> )
         }
         </li>
          <li>В базу "{ $базыДляЗагрузки[ 2 ] }"
          {
           if( $checkSecondary )
             then(
                 <span  class = 'text-success'>
                   файл загружен:   
                     (<a href = "{ $checkSecondary/DOWNLOAD_URL/text()}">скачать</a>)
                 </span>
               )
             else( <span class = 'text-danger'>файл еще не загружен</span> )
         }</li>
         </ul>
       </div>
      
       {
         let $сообщениеЗагрузка :=
           for $i in tokenize( $message, ';' )
           count $c
           let $класс := 
             if( substring-before( $i, ':' ) = 'error' )
             then( 'text-danger' )
             else( 'text-info' )
           return
             <li class="form-group my-1">
               <label>Загрузка в базу { $базыДляЗагрузки[ $c ] }: <b class = '{ $класс }'>{ $i }</b></label>
             </li>
             
         
         let $формаЗагрузкиФайла :=
               (
                 <form action = "{ '/sandbox/ivgpu/api/v01/generate/РПД.Титул/' || $id || '/' || $disc || '/upload' }" method = 'post' class = "my-1">
                 <input class = "btn btn-success" type = 'submit' value = 'Сгенерировать и отправить в базу'/>
               </form>,
               <form action = "{ '/sandbox/ivgpu/api/v01/generate/РПД.Титул/' || $id || '/' || $disc || '/upload.self' }" method = 'post' enctype="multipart/form-data" class = "my-1">
                 <input class = "btn btn-success" type = 'submit' value = 'Загрузить свой файл'/>
                 <input type = 'file' name = 'file'  required = 'yes'/>
               </form>
               )
          return
            if( not( $checkRoot ) and ( 1 or session:get( 'department' ) =  $дисциплина/@КодКафедры/data() ) )then( $сообщениеЗагрузка, $формаЗагрузкиФайла )else( $сообщениеЗагрузка , 'У Вас нет прав для автозагрузки или РПД уже загружена в базу')
       }
       <div class = 'py-2'>
         <input class = "btn btn-primary" form = 'disc' type="submit" value = "Сохранить выбор дисцилин" formaction = "/sandbox/ivgpu/api/v01/programms/{ $id }/{ $дисциплина/@КодДисциплины/data() }/comp" formmethod = "post"/>
         {
           if( normalize-space( $дисциплина/@Название/data() ) = $fileContentList )
           then(
             <a class = "btn btn-secondary" href = "{ $hrefРПД }">Скачать РПД</a>,
             <a class = "btn btn-secondary" href = "{ $hrefA || '?mode=s' }">Скачать аннотацию</a>
           )
           else(
             <a class = "btn btn-secondary" href = "{ $hrefA || '/шаблон.содержания' }">Скачать шаблон содержания</a>
           )
         }
       </div>

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
  let $tpl := doc( "../../html/main.tpl.html" )
  return
    $tpl update insert node $result into .//body
     
};

(:
  сохраняет выбор дисциплин "до" и "после"
:)

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