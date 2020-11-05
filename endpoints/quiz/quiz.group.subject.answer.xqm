module namespace qq = 'sandbox/ivgpu/вопросник/ответы';

import module namespace funct = 'sandbox/ivgpu/вопросник/функции' at 'functions.xqm';

import module namespace 
  данные = 'sandbox/ivgpu/вопросник/модули/данные'
    at 'modules/modules.data.xqm';

declare variable  $qq:вопросыПутьГугл := 
    'https://docs.google.com/spreadsheets/d/e/2PACX-1vTyFIaIv-44-MM7w5qcS7HHggEktJfyp9mwYoH2kYCmRYGiQFMMJ8zhvJOYepQAEmJYQyd8i7ag_UNp/pub?output=xlsx';

declare
  %rest:path( '/sandbox/ivgpu/вопросник/{$группа}/{$дисциплина}/ответы' )
  %output:method( 'xhtml' )
function qq:main( $группа, $дисциплина ){
   let $ответы := 
      for $i in qq:комбинацияОтветов( $дисциплина )
      return        
          <li>{$i/text()}</li>

   let $params := 
     map{
       'заголовок' : <div class = 'h3'>{ $дисциплина }</div>,
       'данные' : <ol>Материалы для самоподготовки:{$ответы}</ol>,
       'экзаменационныйЛист' : ''
     }
   return
     funct:tpl( '/src/main.html', $params )
};

declare function qq:комбинацияОтветов( $дисциплина ){
  let $data :=
    данные:получитьГуглТаблицу( $qq:вопросыПутьГугл )
    /file/table[ matches( @label, 'Вопросы' ) ]
    /row[ cell[ @label = 'Дисциплина' ] = $дисциплина ]
  
  let $ответы := $data/cell[ matches( @label, 'Ответ' ) ]
  
  return
    for $i in 1 to 4
    return
      $ответы[ $i ] 
};