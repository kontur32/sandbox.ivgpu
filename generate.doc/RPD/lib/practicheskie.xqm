module  namespace
  практические = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/практические';

import module  namespace
  дисциплиныПоСеместрам = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/дисциплиныПоСеместрам'
  at 'discipliniPoSemestram.xqm';
  
declare

function
  практические:практические(
    $содержание as element( table ),
    $дисциплина as element( Дисциплина )
  )
{
  let $темыПоСеместрам := дисциплиныПоСеместрам:модули( $содержание )
 
  let $таблицаТемыПоСеместрам :=
    for $i in $дисциплина/видыРабот/видРабот
    let $семестр := $i/семестр/text()
    group by $семестр
    count $c
    let $темыСеместра := $темыПоСеместрам[ $c ]/cell
    return
      <семестр>
      <row>
        <cell></cell>
        <cell>{ $семестр } семестр</cell>
        <cell>{ sum( $i[ кодВидаРабот/text() = ( '102', '103' ) ]/часы/text() ) }</cell>
      </row>
      {
      for $j in $темыСеместра
      count $номерТемы
      return
      <row>
        <cell>{ $номерТемы + count( $темыПоСеместрам[ $c - 1 ]/cell ) }.</cell>
        { $j }
        <cell>
          {
            round(
              sum(
                $i[ кодВидаРабот/text() = ( '102', '103' ) ]/часы/text()
              ) div count( $темыСеместра ), 1 
            )
          }
         </cell>
      </row>
    }
    </семестр>
  
  let $всегоЧасов :=
    <row>
        <cell></cell>
        <cell>Всего</cell>
        <cell>{ sum( $дисциплина/видыРабот/видРабот[ кодВидаРабот/text() = ( '102', '103' ) ]/часы/text() ) }</cell>
      </row>
    
  return
    <table>
      { $таблицаТемыПоСеместрам/row }
      { $всегоЧасов }
    </table>
};