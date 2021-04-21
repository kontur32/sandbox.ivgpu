module namespace ivgpu = 'subjects.Departments.List';

import module namespace session = "http://basex.org/modules/session";

import module namespace 
  check = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/проверкаНаличияРПД'
    at 'generate.doc/RPD/generate.RPD.check.xqm';

import module namespace 
  data = '/sandbox/ivgpu/generate/data'
    at 'generate.doc/generate.data.xqm';

declare 
  %rest:path( '/sandbox/ivgpu/statistic/lists/subjects/{ $disc }/directions' )
  %rest:query-param( 'dep', '{ $dep }', '21' )
  %rest:query-param( 'filter', '{ $filter }', 'no' )
  %rest:query-param( 'year', '{ $year }', '2016,2017,2018,2019,2020' )
  %rest:query-param( 'дата', '{ $дата }' )
  %output:method( 'xhtml' )
function ivgpu:view( $disc, $filter, $year, $dep, $дата ){
   
   let $setAuth :=
     if( $дата = '1844-02-20' )
     then( session:set( 'auth', 'ok' ) )
     else( if( $дата = 'logout' )then( session:delete( 'auth' ) )else() )
   
   let $auth := if( session:get( 'auth' ) )then( true() )else( false() )
   
   let $years := tokenize( $year, ',' )
 
   let $ООПнаАккредитацию :=
      let $csv := 
        fetch:text( 'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=731239307&amp;single=true&amp;output=csv' ) 
        return
          csv:parse( $csv, map{ 'header' : true() } )
          /csv/record/ID/tokenize( replace( text(), '\s', '' ), ',' )
   
   let $d := 
     data:getProgrammData()
     [ if( $filter != 'no')then( Файл/@ID/data() = $ООПнаАккредитацию )else( true() ) ]
     [ Дисциплины/Дисциплина/@Название/data() = web:decode-url( $disc ) ]
     [ @Год = $years ]
  
  let $items :=   
    for $i in $d
    let $дисциплина := $i/Дисциплины/Дисциплина[ @Название/data() = web:decode-url( $disc )  ]
    
    where  if( $dep )then( $дисциплина/@КодКафедры/data() = $dep )else( true() )
    order by $i/@ФормаОбучения/data()
    order by $дисциплина/@КодКафедры/number( data() )
    
    let $urlРУПа := $i/Файл/@DETAIL__URL/data()
    
    let $urlРУПаЕксель := replace( $urlРУПа, '.plx', '.plx.xls' )
    
    let $check := check:check( $i/Файл/@ID/data(),  $дисциплина/@КодДисциплины/data() )/item
    
    let $маркер :=
      if( $check )
      then( <span style = 'color : green;'>&#9679;</span> )
      else( <span style = 'color : red;'>&#9679;</span> )
    
    let $hrefUpload := 
      '/sandbox/ivgpu/api/v01/generate/РПД.Титул/' || $i/Файл/@ID/data() || '/' || web:encode-url( $дисциплина/@КодДисциплины ) || '/upload'
    
    return
       <li>
         { $маркер }{ $i/@КодНаправления/data() } : { $i/@НазваниеПрофиля/data() } (<a href = "{ $urlРУПа }">{ $i/Файл/@ID/data() }</a>, <a href = "{ $urlРУПаЕксель }">excel</a>) : { $i/@Год/data() } : { $i/@ФормаОбучения/data() } : кафедра - { $дисциплина/@КодКафедры/data() }
         {
           if( $check )
           then(
             <span  class = 'text-success'>
               файл загружен  
               (
                 <a href = "{ $check/DOWNLOAD_URL/text() }">скачать</a>,
                 <a href = "{ $check/DETAIL_URL/text() }" target = '_blank'>просмотреть</a>
               )
             </span>
           )
           else(
             if( $auth )
             then( <a href = '{ $hrefUpload }'><button>загрузить</button></a> )
             else()
           )
         }
       </li>
  
  return
    <html>
      <body>
        <h2>Дисциплина "{ $disc }" в РУПах { string-join( sort( $years ), ', ' ) } годов приёма</h2>
        <div>Всего: { count( $items ) } шт.</div>
        <div>
          <form action = "{ '/sandbox/ivgpu/statistic/lists/subjects/' || $disc || '/directions' }" class = "my-1">
               <input type = 'hidden' name = 'dep' value = '{ $dep }' />
               {
                 element{ 'input' }{
                   attribute { 'type' }{ "radio" },
                   attribute { 'name' }{ "filter" },
                   attribute { 'value' }{ "no" },
                   if( $filter = 'no' )then( attribute { 'checked' }{ "yes" } )else(),
                   'все ООП'
                 }
               }
              {
                 element{ 'input' }{
                   attribute { 'type' }{ "radio" },
                   attribute { 'name' }{ "filter" },
                   attribute { 'value' }{ "yes" },
                   if( $filter != 'no' )then( attribute { 'checked' }{ "yes" } )else(),
                   'ООП на аккредитацию'
                 }
               }
               
               <input type = 'submit' value = 'фильтр'/>
            </form>
        </div>
        <div>Кафедра:
          {
           let $кафедры := 
             $d//Дисциплины/Дисциплина
            [ @Название/data() = web:decode-url( $disc ) ]/@КодКафедры/data()
           for $i in $кафедры
           let $номерКафедры := number( $i )
           order by $номерКафедры
           group by $номерКафедры
           return
             <a href = "?dep={ $i[ last() ] }&amp;filter={ $filter }">{ $i[ last() ] }</a>
          }
        </div>
        
        <div>Статус авторизации: 
          { if( session:get( 'auth' ) = 'ok' )then( 'ok' )else( 'нет' ) }
        </div>
        {
          if( $auth )
          then(
            <form action = "{ '/sandbox/ivgpu/statistic/lists/subjects/' || $disc || '/directions' }" class = "my-1">
               <input type = 'hidden' name = 'dep' value = '{ $dep }' />
               <input type = 'hidden' name = 'filter' value = '{ $filter }' />
               <input type = 'hidden' name = 'дата' value = 'logout' />
               <input type = 'submit' value = 'выйти'/>
            </form>
          )
          else(
            <form action = "{ '/sandbox/ivgpu/statistic/lists/subjects/' || $disc || '/directions' }" class = "my-1">
               <div class="form-group my-1">
                 <label>"Назовите слово..." (c) Л. Якубович</label>
               </div>
               <input type = 'hidden' name = 'dep' value = '{ $dep }' />
               <input type = 'hidden' name = 'filter' value = '{ $filter }' />
               <input type = 'text' name = 'дата'/>
               <input type = 'submit' value = 'Отправить'/>
            </form>
          )
        }
        
        <ol> { $items }</ol>  
      </body>
    </html>
};