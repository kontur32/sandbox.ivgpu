module namespace qq = 'sandbox/ivgpu/вопросник/ответы';

import module namespace q = 'sandbox/ivgpu/вопросник' at 'вопросник.группа.дисциплина.xqm';

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
       'дисциплина' : $дисциплина,
       'данные' : <ol>Материалы для самоподготовки:{$ответы}</ol>,
       'экзаменационныйЛист' : ''
     }
   return
     q:tpl( $params )
};

declare function qq:комбинацияОтветов( $дисциплина ){
  let $path := 
    'https://docs.google.com/spreadsheets/d/e/2PACX-1vTyFIaIv-44-MM7w5qcS7HHggEktJfyp9mwYoH2kYCmRYGiQFMMJ8zhvJOYepQAEmJYQyd8i7ag_UNp/pub?output=xlsx'
  
  let $data :=
    q:request( $path )/file/table[ @label = 'Вопросы' ]
    /row[ cell[ @label = 'Дисциплина' ] = $дисциплина ]
  
  let $ответы := $data/cell[ matches( @label, 'Ответ' ) ]
  
  return
    for $i in 1 to 4
    return
      $ответы[ $i ] 
};