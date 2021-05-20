module  namespace
  практические = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/практические';

import module  namespace
  дисциплиныПоСеместрам = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/дисциплиныПоСеместрам'
  at 'discipliniPoSemestram.xqm';

import module  namespace
  распределениеЧасов = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/распределениеЧасов'
  at 'raspredelenieChasov.xqm';
  
declare
  %public
function
  практические:практические(
    $содержание as element( table ),
    $дисциплина as element( Дисциплина )
  )
{
  let $видыРабот := ( '102', '103' )
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
      </row>
      {
      
      let $распределениеЧасовПоЛекциям :=
        function( $кодВидРабот, $темыТекущегоСеместра ){
          распределениеЧасов:распределениеЧасоПоТемам(
            count( $темыТекущегоСеместра ),
            xs:integer(
              sum( $i[ кодВидаРабот/text() = $кодВидРабот ]/часы/text() )
            )
          )
        }
      
      let $распределениеЧасовПоЛекциям1 :=
        function( $темыТекущегоСеместра ){
          let $практические :=
            распределениеЧасов:распределениеЧасоПоТемам(
              count( $темыТекущегоСеместра ),
              xs:integer(
                sum( $i[ кодВидаРабот/text() = '102' ]/часы/text() )
              )
            )
          let $лабораторные := 
            распределениеЧасов:распределениеЧасоПоТемам(
              count( $темыТекущегоСеместра ),
              xs:integer(
                sum( $i[ кодВидаРабот/text() = '103' ]/часы/text() )
              )
            )
          for $j in 1 to count( $темыТекущегоСеместра )
          count $c
          return
            $практические[ $c ] + $лабораторные[ $c ]
        }
      
      for $j in $темыСеместра
      count $номерТемы
      let $часовНаТему := 
        $распределениеЧасовПоЛекциям1( $темыСеместра )[ $номерТемы ]
      where $часовНаТему > 0
      count $текущийНомер
      return
      <row>
        <cell>{ $номерТемы }</cell>
        <cell>{ replace( $j/text(), 'Тема\s{0,}\d{0,2}\.\s{0,}', '') }</cell>
        <cell>{ $часовНаТему }</cell>
      </row>
    }
      <row>
        <cell></cell>
        <cell>Итого за семестр</cell>
        <cell>{ sum( $i[ кодВидаРабот/text() = $видыРабот ]/часы/text() ) }</cell>
      </row>
    </семестр>
  
  let $таблицаТемыПоСеместрам :=
    for $ii in $таблицаТемыПоСеместрам
    count $c
    let $темДо :=
      count( $таблицаТемыПоСеместрам[ $c - 1 ]/row[ cell[1]/text() ] )
    return
      <семестр>{
        for $jj in $ii/row
        count $cc
        return
          $jj update replace value of node ./cell[ 1 ] 
          with if( ./cell[ 1 ]/text() )then( $темДо + $cc - 1 )else("")
      }</семестр>
  
 
  
  let $всегоЧасов :=
    <row>
        <cell></cell>
        <cell>Всего</cell>
        <cell>{ sum( $дисциплина/видыРабот/видРабот[ кодВидаРабот/text() = $видыРабот ]/часы/text() ) }</cell>
      </row>
    
  return
    <table>
      { $таблицаТемыПоСеместрам/row }
      { $всегоЧасов }
    </table>
};