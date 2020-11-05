module namespace вопросы = 'sandbox/ivgpu/вопросник/билетыСтудента';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at 'functions.xqm';
    
import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at 'modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/группы/{$группа}/студенты/{$студент}/билеты' )
  %output:method( 'xhtml' )
function вопросы:main( $группа, $студент ){
  let $номераБилетов := данные:номераБилетов()
  let $билеты := данные:билетыСтудента( $студент, $группа )
  let $result :=
    for $i in $билеты/row
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
    
    return
      <div style="height: 180mm; width: 100%" class = "билет">
        <div class = 'row' >
          <span class = 'h4'><span class = 'pr-2'>
            Билет № { $номераБилетов[ $c ] }
          </span>
          Предмет: { $дисциплина }<a class = 'pl-2 no-print' href ="{$i/cell[@label = 'Ссылка Мудл']/text()}">(курс в Мудл)</a>
          </span>
        </div>
        <div class = 'row' style="height: 47%;">
          <div class = 'col-12 h5'>Вопрос № 1: { $i/cell[ 1 ]/text() }</div>
          <div class = 'col-9 h-75 border'>Ответ:</div>
          <div class = 'col-3 h-75 text-center border'>
            <a href = "{ $короткаяСсылка }">
              <span class = 'py-0 my-0'>Подсказка</span>
              <img class="img py-0 my-0" style="height: 100%;" src = '{ $qrHref }'/>
            </a>
          </div>
        </div>
        <div class = 'row' style="height: 47%;">
          <div class = 'col-12 h5'>Вопрос № 2: { $i/cell[ 2 ]/text() }</div>
          <div class = 'col-9 h-75 border'>Ответ:</div>
          <div class = 'col-3 h-75 border'></div>
        </div>
      </div>
      
   let $params := 
    map{
      'заголовок' : <div>Студент: <span class = 'h3 text-left'>{$билеты/@label/data()} (группа: <span><a href = "{ '/sandbox/ivgpu/вопросник/группы/' ||  $группа || '/студенты/' }">{ $группа }</a></span>)</span></div>,
      'данные' : $result,
      'экзаменационныйЛист' : <div class = 'article d-none' style="width: 100%;"></div>
    }
   return
     funct:tpl( '/src/main.html', $params )
};
 