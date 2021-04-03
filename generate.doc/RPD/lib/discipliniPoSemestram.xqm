module  namespace
  дисциплиныПоСеместрам = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/дисциплиныПоСеместрам';
  
declare function дисциплиныПоСеместрам:модули( $содержание as element( table ) )
  as element( семестр )*
{
  
  let $строкиСодержания := $содержание/row    

  let $номераСтрокМодулей := 
    (
      if( $строкиСодержания/cell[ starts-with( text(), 'Модуль' ) ] )
      then
      (
        for $i in $строкиСодержания
        count $c
        where $i/cell[ starts-with( text(), 'Модуль' ) ]
        return
         $c
      )
      else( 0 ),
      count( $строкиСодержания )
    )  
   
  return
    for $i in $номераСтрокМодулей
    count $c
    let $следующийМодуль := $номераСтрокМодулей[ $c + 1 ]
    where $следующийМодуль <=  count( $строкиСодержания )
    return
      <семестр>
      {
        $строкиСодержания[ position() > $i and position() < $следующийМодуль ]/cell[ starts-with( text(), 'Тема') ]
      }
      </семестр>
};