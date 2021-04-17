module  namespace
  распределениеЧасов = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/распределениеЧасов';

(:~
 : Распеределяет часы по темам
 : @param  $количествоТем  количество тем
 : @param  $количествоЧасов  количество часов
 : @return ряд чисел (по количеству тем), сумма которых равна количеству часов
 :) 
declare
  %public
function
  распределениеЧасов:распределениеЧасоПоТемам(
    $количествоТем as xs:integer,
    $количествоЧасов as xs:integer
  ) as xs:integer*
{
  let $целые := $количествоЧасов idiv $количествоТем 
  let $остаток := $количествоЧасов - $количествоТем * $целые

  for $i in 1 to $количествоТем
  count $c
  let $признакДобавки := 
    round( $остаток div $количествоТем * $c ) > 
    round( $остаток div $количествоТем * ( $c - 1 ) )
  let $добавкаЧаса := if( $признакДобавки )then( 1 )else( 0 )
  return
     $целые + $добавкаЧаса
};