module namespace вопросы = 'sandbox/ivgpu/вопросник/билетыСтудента';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at '../functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at '../modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы/{$группа}/студенты/{$студент}/билеты' )
  %rest:query-param( 'раздел', '{ $раздел }', 'все')
  %rest:query-param( 'преподаватель', '{ $преподаватель }', 'все' )
  %output:method( 'xhtml' )
function вопросы:main( $группа, $студент, $раздел, $преподаватель ){
  
  let $номераБилетов := данные:номераБилетов()
  
  let $билеты := данные:билетыСтудента( $студент, $группа )
  
  let $билетыОтбор := 
    $билеты/row
    [
      if( $преподаватель != 'все' )
      then( cell[ @label = 'Преподаватель' ] = $преподаватель )
      else( true() )
    ]
  
  let $списокПреподавателей :=
    distinct-values(
      $билеты[ @label/data() = $студент ]/row/cell[ @label = 'Преподаватель' ]/text()
    )
  
  let $result :=
    for $i in $билетыОтбор
    count $c
    let $дисциплина := $i/@label/data()
    let $ссылкаНаПодсказки :=
      iri-to-uri( 'https://clck.ru/--?url=http://dbx.iro37.ru/sandbox/ivgpu/вопросник/' || $группа ||'/' || $дисциплина || '/ответы' )
    let $короткаяСсылка :=
      fetch:text( $ссылкаНаПодсказки )
    
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
     count $c
     let $дисциплина := $i/@label/data()
     let $текущийПреподаватель := $i/cell[ @label = "Преподаватель"]/text()
     let $ФИО :=
       let $t := tokenize( $текущийПреподаватель )
       return
         substring( $t[ 2 ], 1, 1 ) ||'.'
         ||substring( $t[ 3 ], 1, 1 ) ||'. '||
         $t[ 1 ]
     let $p :=
         map{
           'номерЛиста' : $c,
           'курс' : substring( replace( $группа, '\D', ''), 1, 1 ),
           'группа' : $группа,
           'дисциплина' : $дисциплина,
           'формаОтчетности' : "__________",
           'оценка' : вопросы:списокОценок( "", 'лист' || $c ),
           'студент' : $студент,
           'преподаватель' : $текущийПреподаватель,
           'ФИОпреподавателя' : $ФИО,
           'текущаяДата' : substring-before( xs:string( current-date() ), '+')
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
 
declare function вопросы:списокОценок( $формаОтчетности, $имяФормы ){
  let $список :=
    switch ( $формаОтчетности )
    case 'зачет'
      return 
        <select class="form-control col-sm-4" id="exampleFormControlSelect1" form = "{$имяФормы}" name = 'оценка' style="display:inline-block;">
          <option selected = "selected">зачет</option>,
          <option>не зачет</option>
        </select>
    case ''
      return
         <div class="col-sm-3">
            <div class = "no-print">
              <input form = "{ $имяФормы }" name = "оценка" type="text" class="form-control" id="inputPassword" placeholder="Оценка"/>
            </div>
         </div>
    default 
      return
        <select class="form-control col-sm-6" id="exampleFormControlSelect1" form = "{$имяФормы}" name = 'оценка' style="display:inline-block;">
          <option>неудовлетворительно</option>,
          <option selected = "selected">удовлетворительно</option>,
          <option>хорошо</option>,
          <option>отлично</option>
       </select>
   return
     <div class="form-group row mb-0">
        <label for="exampleFormControlSelect1" class = "col-sm-4">Оценка</label>
          { $список }
      </div>
};
 
 declare function вопросы:формаРазделов( $раздел ){
   <div class="form-group mb-0">
     {
     <form action = "#" id = "форма">
       <input class = "mr-1" type = "radio" name = "раздел" value = "все">Показать все</input>
       <input class = "mr-1" type = "radio" name = "раздел" value = "билеты">Только билеты</input>
       <input class = "mr-1" type = "radio" name = "раздел" value = "листы">Только экзам. листы</input>
       <input type = "submit" class="mr-1 btn btn-primary" value = "Обновить"/>
     </form>
     update insert node attribute { 'checked' } { 'yes' } into ./input[ @value/data() = $раздел ]
     }
   </div>
 };
 
 declare function вопросы:списокПреподавателей( $список, $преподаватель ){
   <div class="form-group row">
    <label for="exampleFormControlSelect1" class = "col-5">Выберите преподавателя</label>
    <select class="form-control col-7" id="exampleFormControlSelect1" form = "форма" name = 'преподаватель' style="display:inline-block;">
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