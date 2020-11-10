module namespace вопросы = 'sandbox/ivgpu/вопросник/билетыСтудента';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at 'functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at 'modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы/{$группа}/студенты/{$студент}/билеты' )
  %rest:query-param( 'раздел', '{ $раздел }', 'все')
  %rest:query-param( 'преподаватель', '{ $преподаватель }', 'все' )
  %output:method( 'xhtml' )
function вопросы:main( $группа, $студент, $раздел, $преподаватель ){
  
  let $номераБилетов := данные:номераБилетов()
  
  let $билеты := 
    данные:билетыСтудента( $студент, $группа )
  
  let $билетыОтбор := 
    $билеты/row
    [ if( $преподаватель != 'все' )then( cell[ @label = 'Преподаватель' ] = $преподаватель )else( true() ) ]
  
  let $списокПреподавателей :=
    distinct-values(
      $билеты[ @label/data() = $студент ]/row/cell[ @label = 'Преподаватель' ]/text()
    )
  
  let $result :=
    for $i in $билетыОтбор
    count $c
    let $дисциплина := $i/@label/data()
    let $короткаяСсылка :=
      fetch:text( iri-to-uri( 'https://clck.ru/--?url=http://dbx.iro37.ru/sandbox/ivgpu/вопросник/' || $группа ||'/' || $дисциплина || '/ответы' ) )
    
    let $qrHref := 
      web:create-url(
        'https://chart.googleapis.com/chart',
        map{
          'cht': 'qr',
          'chs' : '200x200',
          'choe' : 'UTF-8',
          'chld' : 'H',
          'chl' : $короткаяСсылка
        }
      )
    let $p := 
      map{
        'номерБилета' : $номераБилетов[ $c ],
        'дисциплина' : $дисциплина,
        'ссылкаНаМудл' : $i/cell[@label = 'Ссылка Мудл']/text(),
        'вопросПервый' : $i/cell[ @label = 'Вопрос 1' ]/text(),
        'короткаяСсылка' : $короткаяСсылка,
        'QRссылка' : $qrHref,
        'вопросВторой' : $i/cell[ @label = 'Вопрос 2' ]/text()
      }
    return
       funct:tpl( '/src/bilet.html', $p )
   
   let $экзЛист :=
     for $i in $билетыОтбор
     let $дисциплина := $i/@label/data()
     let $p :=
         map{
           'группа' : $группа,
           'дисциплина' : $дисциплина,
           'студент' : $студент,
           'преподаватель' : $i/cell[ @label = "Преподаватель"]/text()
         }
     return
       funct:tpl( '/src/examBlank.html', $p )
   
   let $данные := 
     (
       
       if( $раздел !=  'листы' )then( $result )else(),
       if( $раздел =  'все' )then( <div id = 'разрыв'></div> )else(),
       if( $раздел !=  'билеты' )then( <div>{ $экзЛист }</div> )else()
     )
   
   let $заголовок :=
     <div>
       <div>Студент:</div>
       <span class = 'h3 text-left'>
         {$билеты/@label/data()} (группа: <span><a href = "{ '/sandbox/ivgpu/вопросник/группы/' ||  $группа || '/студенты/' }">{ $группа }</a></span>)
       </span>
     </div>
       
   let $params := 
    map{
      'заголовок' : $заголовок,
      'данные' : $данные,
      'меню' : (<div class = 'col-6 mt-4'>{ вопросы:формаРазделов( $раздел ) }</div>,
       <div class = 'col-6 mt-4'>{ вопросы:списокПреподавателей( $списокПреподавателей, $преподаватель ) }</div>),
      'экзаменационныйЛист' : ''
    }
   return
     funct:tpl( '/src/main.html', $params )
};
 
 declare function вопросы:формаРазделов( $раздел ){
   <div class="form-group mb-0">
     {
     <form action = "#" id = "форма">
       <input type = "radio" name = "раздел" value = "все">Показать все</input>
       <input type = "radio" name = "раздел" value = "билеты">Только билеты</input>
       <input type = "radio" name = "раздел" value = "листы">Только экзам. листы</input>
       <input type = "submit" class="btn btn-primary" value = "Обновить"/>
     </form>
     update insert node attribute {'checked'} {'yes'} into ./input[ @value/data() = $раздел ]
     }
   </div>
 };
 
 declare function вопросы:списокПреподавателей( $список, $преподаватель ){
   <div class="form-group row">
    <label for="exampleFormControlSelect1" class = "col">Выберите преподавателя</label>
    <select class="form-control col" id="exampleFormControlSelect1" form = "форма" name = 'преподаватель' style="display:inline-block;">
      <option>все</option>
      {
        for $i in $список
        return
           <option>{ $i }</option>
      }
    </select>
  </div>
  update insert node attribute { 'selected' }{ 'selected' } into ./select/option[ text() = $преподаватель ]
 };