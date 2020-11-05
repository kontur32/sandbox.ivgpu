module namespace вопросы = 'sandbox/ivgpu/вопросник/вопросы';

import module namespace 
  funct = 'sandbox/ivgpu/вопросник/функции'
    at 'functions.xqm';

import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at 'modules/modules.data.xqm';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/{$группа}/{$дисциплина}' )
  %output:method( 'xhtml' )
function вопросы:main( $группа, $дисциплина ){
  let $номераБилетов := данные:номераБилетов()
  
  let $result := 
    let $комбинацияВопросов := 
      данные:комбинацияВопросов(
        данные:получитьВопросыПоДисциплине(
          данные:получитьВсеВопросы( $группа ), $дисциплина
        )
      )
    for $i in $комбинацияВопросов
    count $c
    let $короткаяСсылка :=
      fetch:text( iri-to-uri( 'https://clck.ru/--?url=http://dbx.iro37.ru/sandbox/ivgpu/вопросник/' || $группа ||'/' || $дисциплина || '/ответы' ) )
    
    let $qrHref := 
      web:create-url(
        'https://chart.googleapis.com/chart',
        map{
          'cht': 'qr',
          'chs' : '200x200',
          'choe' : 'UTF-8',
          'chl' : $короткаяСсылка
        }
      )
    
    return
      <div style="height: 180mm; width: 100%" class = "билет">
        <div class = 'row h4' ><span class = 'pr-2'>Билет № { $номераБилетов[ $c ] }</span>(Предмет: { $дисциплина })</div>
        <div class = 'row' style="height: 47%;">
          <div class = 'col-12 h5'>Вопрос № 1: { $i?1 }</div>
          <div class = 'col-9 h-75 border'>Ответ:</div>
          <div class = 'col-3 h-75 text-center border'>
            <a href = "{ $короткаяСсылка }">
              <img class="img" style="height: 100%;" src = '{ $qrHref }'/>
            Подсказка
            </a>
            
          </div>
        </div>
        <div class = 'row' style="height: 47%;">
          <div class = 'col-12 h5'>Вопрос № 2: { $i?2 }</div>
          <div class = 'col-9 h-75 border'>Ответ:</div>
          <div class = 'col-3 h-75 border'></div>
        </div>
      </div>
   
   let $экзаменационныйЛист := 
    for $i in  ( 1 to 2 ) 
    return
      <div style="height: 180mm; width: 100%" class = "container mb-2 border">
        <div class = 'row'>
          <div class = 'col-12 h2 text-center'>ЭКЗАМЕНАЦИОННЫЙ ЛИСТ</div>
        </div>
      </div>
      
   let $params := 
    map{
      'заголовок' : <div>Билеты по дисциплине: <span class = 'h3 text-left'>{$дисциплина}</span></div>,
      'данные' : $result,
      'экзаменационныйЛист' : <div class = 'article d-none' style="width: 100%;">{$экзаменационныйЛист}</div>
    }
   return
     funct:tpl( '/src/main.html', $params )
};