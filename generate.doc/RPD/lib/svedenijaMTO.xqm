module  namespace
  сведенияМТО = '/sandbox/ivgpu/api/v01/generate/РПД.Титул/сведенияМТО';

import module namespace 
  ivgpu = '/sandbox/ivgpu/plans.datafile.build'
  at '../../../plans.datafile.build.xqm';

import module namespace data = '/sandbox/ivgpu/generate/data'
  at '../../generate.data.xqm';
  
declare namespace w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";

declare 
  %public
function
  сведенияМТО:получить( $программа, $дисциплина )
{
  let $названиеДисциплины := $дисциплина/@Название/data() 

  let $кодНаправления := replace( $программа/@КодНаправления/data(), '\.', '' )
  
  let $профиль :=
    let $csv :=
      fetch:text(
        'https://docs.google.com/spreadsheets/d/e/2PACX-1vSG_nG0Rfo3iJndyRD3WKPrukd4gNR1FYP0MVu6ddveIGNRkKX21vdUp6D0P4rMxJBVwgWLW35y-Lr7/pub?gid=791606169&amp;single=true&amp;output=csv'
      )
     return
      csv:parse( $csv, map{ 'header' : true() } )
      /csv/record
      [ Направление = $программа/@КодНаправления/data() ]
      [ Профиль = $программа/@НазваниеПрофиля/data() ][ 1 ]
      /Сокращение/text()
  
  let $url := 
    let $список :=
      ivgpu:getFolderList( '342814', '0' ) (: корневая папка с МТО :)
      /json/result/_
    let $имя :=
      $кодНаправления || '_' || $профиль
    return
      $список
      [ NAME [ matches( text(), $имя )  ] ][ 1 ]
      /DOWNLOAD__URL/text()
  
  let $результат :=
    if( $url != "" )
    then(
      let $contentFile := 
        try{ [ fetch:binary( $url ), '1' ] }catch*{ }
      return
        сведенияМТО:МТОизСправки( $contentFile?1, $названиеДисциплины )
    )
    else()
   return
    if( $результат/row )
    then( $результат )
    else(  сведенияМТО:МТОумолчание() )
};

declare
  %public
function сведенияМТО:МТОизСправки( $справкаМТО, $названиеДисциплины ) as element( table ){
  let $data := 
    parse-xml ( 
        archive:extract-text( $справкаМТО,  'word/document.xml' )
    )/*:document//*:tbl[1]
    
  return
    <table>{
      for $row in $data//w:tr
      
      where $row/w:tc[ 2 ]
      [ normalize-space( string-join( w:p/w:r/w:t/ text() ) ) =  $названиеДисциплины ]
      
      for $p in $row/w:tc[ 3 ]/w:p
      let $строка := 
        normalize-space( string-join( $p//w:t/text() ) )
      where $строка
      return
        <row>
          <cell>{ $строка }</cell>
        </row>
    }
    </table>
};

declare
  %public
function сведенияМТО:МТОумолчание() as element( table ) {
  let $csv :=
    fetch:text(
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vReXB9sdATLZx1KZAHGrLI6FxIot1IF13QHwlANmDwnnV9yQFPrmGIm69-22-QENKeBXL6xojbYccCx/pub?gid=0&amp;single=true&amp;output=csv'
    )
  let $data :=
    csv:parse( $csv, map{ 'header' : true() } )
    /csv/record
  return
    <table>{
      for $i in $data
      return
        <row>
          <cell>{ $i/Абзац/text() }</cell>
        </row>
    }</table>
};