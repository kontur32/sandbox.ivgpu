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
  let $fieldName := $дисциплина/@Название/data() 

  let $кодНаправления := replace( $программа/@КодНаправления/data(), '\.', '' )
  
  let $профиль := 
    $программа/@НазваниеПрофиля
      /upper-case(
        string-join(
          for-each(
            tokenize( . )[ . != 'и' ], function( $result) { substring( $result, 1, 1 ) }
          ) 
        ) 
      )
  
  let $url := 
    ivgpu:getFolderList( '342814', '0' ) (: корневая папка с МТО :)
    /json/result/_
    [ NAME [ matches( text(), $кодНаправления || '.*' || $профиль ) ] ][ 1 ]
    /DOWNLOAD__URL/text()
  
  let $contentFile := fetch:binary( $url )
  
  let $data := 
    parse-xml ( 
        archive:extract-text( $contentFile,  'word/document.xml' )
    )/*:document//*:tbl[1]
    
  return
    <table>{
      for $row in $data//w:tr
      
      where $row/w:tc[ 2 ]
      [ normalize-space( string-join( w:p/w:r/w:t/ text() ) ) =  $fieldName ]
      
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