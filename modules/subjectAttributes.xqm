module namespace аттрибутыДисциплин = 'аттрибутыДисциплин';

declare namespace a = 'urn:schemas-microsoft-com:xml-diffgram-v1';
declare namespace b = 'http://tempuri.org/dsMMISDB.xsd';

declare 
  %public
function 
  аттрибутыДисциплин:формыКонтроляПоСеместрам3PP(
    $план as element()*, $кодДисциплины as xs:string
  ) as item()*
{
    let $дисциплина :=  $план/b:ПланыСтроки[ @ДисциплинаКод = $кодДисциплины  ]
    let $видыРаботПоДисциплине := 
      $план/b:ПланыНовыеЧасы[ @КодОбъекта = $дисциплина/@Код/data() ]
    let $формыКонтроля := 
      $план/b:СправочникВидыРабот[ @КодТипРабот = '7' ] (: 7 - контроль :)
    let $result := 
      for $i in  $видыРаботПоДисциплине[ @КодВидаРаботы = $формыКонтроля/@Код/data() ]
      let $семестр := ( $i/@Курс - 1 ) * 2 +  $i/@Семестр
      let $формаКонтроля := $формыКонтроля[ @Код = $i/@КодВидаРаботы ]/@Название/data()
      order by $семестр
      return
       [ $семестр,
         $формаКонтроля
       ]
    return
      (
        string-join( $result?1, ','),
        string-join( $result?2, ',')
      )
};