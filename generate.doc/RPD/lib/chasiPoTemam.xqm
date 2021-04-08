module  namespace
  часыПоТемам = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/часыПоТемам';

import module  namespace
  дисциплиныПоСеместрам = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/дисциплиныПоСеместрам'
  at 'discipliniPoSemestram.xqm';

import module  namespace
  распределениеЧасов = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/распределениеЧасов'
  at 'raspredelenieChasov.xqm';

declare
  %public
function 
  часыПоТемам:часыПоТемам(
    $содержание as element( table ),
    $дисциплина as element( Дисциплина )
  )
{
  let $видыРабот := ( '101', '103', '102', '107', '108' )

  let $видыКонтроля := ( '1', '2', '3', '4', '5' )
  
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
        <cell></cell>
        <cell></cell>
        <cell></cell>
        <cell></cell>
        <cell></cell>
        <cell></cell>
      </row>
      {
      
      let $распределениеЧасовПоЛекциям :=
        function( $кодВидРабот ){
          распределениеЧасов:распределениеЧасоПоТемам(
            count( $темыСеместра ),
            xs:integer(
              sum( $i[ кодВидаРабот/text() = $кодВидРабот ]/часы/text() )
            )
          )
        }
      for $j in $темыСеместра
      count $номерТемы
      return
      <row>
        <cell>{ $номерТемы + count( $темыПоСеместрам[ $c - 1 ]/cell ) }.</cell>
        { $j }
        {
          for $видРабот in $видыРабот
          return
            <cell>{ $распределениеЧасовПоЛекциям( $видРабот )[ $номерТемы ] }</cell>
        }
        <cell>
          { $распределениеЧасовПоЛекциям( $видыРабот )[ $номерТемы ] }
        </cell>
      </row>
    }
      <row>
        <cell></cell>
        <cell>Промежуточная аттестация: { string-join( $i[ кодВидаРабот/text() = $видыКонтроля ]/названиеВидаРабота/text(), ', ' ) }</cell>
        <cell></cell>
        <cell></cell>
        <cell></cell>
        <cell></cell>
        <cell>{ sum( $i[ кодВидаРабот/text() = $видыКонтроля ]/часы/text() ) }</cell>
        <cell>{ sum( $i[ кодВидаРабот/text() = $видыКонтроля ]/часы/text() ) }</cell>
      </row>
      <row>
        <cell></cell>
        <cell>Итого по семестру</cell>
        <cell>{ $i[ кодВидаРабот/text() = '101' ]/часы/text() }</cell>
        <cell>{ $i[ кодВидаРабот/text() = '103' ]/часы/text() }</cell>
        <cell>{ $i[ кодВидаРабот/text() = '102' ]/часы/text() }</cell>
        <cell>{ $i[ кодВидаРабот/text() = '107' ]/часы/text() }</cell>
        <cell>{ $i[ кодВидаРабот/text() = '108' ]/часы/text() }</cell>
        <cell>
          { sum( $i[ кодВидаРабот/text() = $видыРабот ]/часы/text() ) }
        </cell>
      </row>
    </семестр>
  
  let $всегоЧасов :=
    <row>
        <cell></cell>
        <cell>Всего</cell>
        {
          for $видРабот in $видыРабот
          return
            <cell>{
              sum( $дисциплина/видыРабот/видРабот[ кодВидаРабот/text() = $видРабот ]/часы/text() )
            }</cell>
        }
        <cell>
          { sum( $дисциплина/видыРабот/видРабот[ кодВидаРабот/text() = $видыРабот ]/часы/text() ) }
        </cell>
      </row>
    
  return
    <table>
      { $таблицаТемыПоСеместрам/row }
      { $всегоЧасов }
    </table>
};