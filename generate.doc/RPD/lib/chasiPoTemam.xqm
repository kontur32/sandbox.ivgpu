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
   let $распределениеЧасовПоЛекциям :=
        function( $кодВидРабот, $темыСеместра, $видРабот ){
          распределениеЧасов:распределениеЧасоПоТемам(
            count( $темыСеместра ),
            xs:integer(
              sum( $видРабот[ кодВидаРабот/text() = $кодВидРабот ]/часы/text() )
            )
          )
        }
  let $видыРабот := ( '101', '103', '102',  '107' )

  let $видыКонтроля := ( '1', '2', '3', '4', '5', '6' )
  
  let $темыПоСеместрам := дисциплиныПоСеместрам:модули( $содержание )
  let $семестрыБезКонтроля := часыПоТемам:семестрБезОценки( $дисциплина )
  let $таблицаТемыПоСеместрам :=
    for $i in $дисциплина/видыРабот/видРабот[ семестр != $семестрыБезКонтроля ]
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
      for $j in $темыСеместра
      count $номерТемы
      let $часыПоВидамРабот := 
        for $видРабот in $видыРабот
        return
          <cell>{ $распределениеЧасовПоЛекциям( $видРабот, $темыСеместра, $i  )[ $номерТемы ] }</cell>
      return
        <row>
          <cell>{ $номерТемы + count( $темыПоСеместрам[ $c - 1 ]/cell ) }.</cell>
          { $j }
          { $часыПоВидамРабот }
          <cell></cell> (: колонка контроля :)
          <cell>{ sum( $часыПоВидамРабот/text() ) }</cell>
        </row>
    }
      <row>
        <cell></cell>
        <cell>Промежуточная аттестация: { string-join( $i[ кодВидаРабот/text() = $видыКонтроля ]/названиеВидаРабота/text(), ', ' ) }</cell>
        <cell></cell>
        <cell></cell>
        <cell></cell>
        <cell></cell>
        <cell></cell>
        <cell></cell>
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
          { sum( $i[ кодВидаРабот/text() = ( $видыРабот, '108' ) ]/часы/text() ) }
        </cell>
      </row>
    </семестр>
  
  let $всегоЧасов :=
    <row>
        <cell></cell>
        <cell>Всего</cell>
        {
          for $видРабот in ( '101', '103', '102', '107', '108' )
          return
            <cell>{
              sum( $дисциплина/видыРабот/видРабот[ кодВидаРабот/text() = $видРабот ]/часы/text() )
            }</cell>
        }
        <cell>
          { sum( $дисциплина/видыРабот/видРабот[ кодВидаРабот/text() = ( $видыРабот, '108' ) ]/часы/text() ) }
        </cell>
      </row>
  let $установочныйСеместр := 
        if( $семестрыБезКонтроля )
        then(
          <семестр>
            <row>
              <cell></cell>
              <cell>{ $семестрыБезКонтроля } семестр</cell>
              <cell></cell>
              <cell></cell>
              <cell></cell>
              <cell></cell>
              <cell></cell>
              <cell></cell>
            </row>
            <row>
              <cell>1.</cell>
              <cell>Установочная лекция</cell>
              <cell>{ $дисциплина/видыРабот/видРабот[ семестр = $семестрыБезКонтроля and кодВидаРабот = '101' ]/часы/text() }</cell>
              <cell></cell>
              <cell></cell>
              <cell></cell>
              <cell></cell>
              <cell></cell>
            </row>
          </семестр>
        )
        else()

  return
    <table>
      { $установочныйСеместр/row }
      { $таблицаТемыПоСеместрам/row }
      { $всегоЧасов }
    </table>
};

declare function часыПоТемам:семестрБезОценки( $дисциплина as element( Дисциплина ) ){
   let $семестры := distinct-values( $дисциплина/видыРабот/видРабот/семестр/text() )
   let $семестрОценка := distinct-values( $дисциплина/видыРабот/видРабот[кодВидаРабот/xs:integer( text() ) = ( 1 to 6 ) ]/семестр/text() )
   let $семестрБезОценки := 
     for-each( $семестры, function( $var ){ if( $var != $семестрОценка )then( $var )else() } )
   return
     $семестрБезОценки
};