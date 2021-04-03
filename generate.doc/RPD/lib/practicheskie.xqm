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
    
    let $log :=
        let $a:=
          $дисциплина/видыРабот/видРабот
          [ семестр/text() < $семестр and кодВидаРабот/text() = $видыРабот ]
        return
          (
            <a>{ count( $a )}</a>,
            <b>{ sum( $a/часы/text() ) }</b>,
            <c>{ $темыПоСеместрам[ position() < $c ] }</c>
          )
   
    return
      <семестр>
      <row>
        <cell></cell>
        <cell>{ $семестр } семестр</cell>
        <cell>{ sum( $i[ кодВидаРабот/text() = $видыРабот ]/часы/text() ) }</cell>
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
      let $часовНаТему := 
        $распределениеЧасовПоЛекциям( $видыРабот )[ $номерТемы ]
      where $часовНаТему > 0
      count $текущийНомер
      return
      <row>
        <cell>{ $семестр }.{ $текущийНомер }.</cell>
        <cell>{ replace( $j/text(), 'Тема\s{0,}\d{0,2}\.\s{0,}', '') }</cell>
        <cell>{ $часовНаТему }</cell>
      </row>
    }
    </семестр>
  
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