module namespace content = '/sandbox/ivgpu/generate/content';

import module namespace functx = "http://www.functx.com";

import module namespace 
  rup = 'subjects.Department.Direction' 
    at '../tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

declare namespace w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";

declare function content:getContent( $fileName, $fields as item()* ){
  let $contentFile := 
   content:getContentFile(
       $fileName
    )
    
  return
    if( $contentFile instance of xs:base64Binary )
    then(
        let $data := 
          parse-xml ( 
              archive:extract-text( $contentFile,  'word/document.xml' )
          )/w:document//w:tbl[ 1 ]
        return
          <table>
            <row id = 'fields'>
              {
                for $field in $fields[ .?2 = 'field']
                return
                  content:buildFieldRecord( $field?1, $data )
              }
            </row>
            <row id = 'tables'>
              {
                for $field in $fields[ .?2 = 'table']
                return
                  content:buildTableRecord( $field?1, $data )
              }
            </row>
            <row id = 'pictures'>
              {
                for $field in $fields[ .?2 = 'picture']
                return
                  content:buildPictureRecord( $field?1, $data )
              }
            </row>
          </table>              
      )
      else(
        <error>Ошибка в полученном файле содержания</error>
      )
};

declare function content:buildRecord( $contentFile, $fields ){
  let $data := 
    parse-xml ( 
        archive:extract-text( $contentFile,  'word/document.xml' )
    )/w:document//w:tbl[ 1 ]
  return
    <table>
      <row id = 'fields'>
        {
          for $field in $fields[ .?2 = 'field']
          return
            content:buildFieldRecord( $field?1, $data )
        }
      </row>
      <row id = 'tables'>
        {
          for $field in $fields[ .?2 = 'table']
          return
            content:buildTableRecord( $field?1, $data )
        }
      </row>
      <row id = 'pictures'>
        {
          for $field in $fields[ .?2 = 'picture']
          return
            content:buildPictureRecord( $field?1, $data )
        }
      </row>
    </table>
};


declare function content:buildTableRecord( $fieldName, $data ) as element( cell ){
    <cell id = '{ $fieldName }'>
      <table>
        {          
          for $row in $data//w:tr
          where $row/w:tc[ 1 ][ w:p/w:r/w:t/text() = $fieldName ]
          for $p in $row/w:tc[ 2 ]/w:p
          return
            <row>
              <cell>{ string-join( $p/w:r/w:t/text() ) }</cell>
            </row> 
        }
      </table>
    </cell>
};

declare function content:buildFieldRecord( $fieldName, $data ) as element( cell ){
  <cell id = '{ $fieldName }' contentType = "field">
    {          
      for $row in $data//w:tr
      where $row/w:tc[ 1 ][ w:p/w:r/w:t/text() = $fieldName ]
      let $text:= string-join( $row/w:tc[ 2 ]/w:p/w:r/w:t/text() )
      return
        $text
    }
  </cell>
};

declare function content:buildPictureRecord( $fieldName, $data ) as element( cell ){
  <cell id = '{ $fieldName }' contentType = "picture">
    {          
      for $row in $data//w:tr
      where $row/w:tc[ 1 ][ w:p/w:r/w:t/text() = $fieldName ]
      let $pictureName:= string-join( $row/w:tc[ 2 ]/w:p/w:r/w:t/text() )
      return
        content:getSignature( $pictureName )
    }
  </cell>
};

declare function content:getSignature( $personName ){
  let $fileList := 
    rup:getFileContentList( '55279' )
      [ TYPE='file' ]
  let $pictureURL := 
    if(
       $fileList
        [ starts-with( replace( NAME/text(), ' ', '' ), replace( $personName, ' ', '' ) ) ]
    )
    then(
      $fileList
        [ starts-with( replace( NAME/text(), ' ', '' ), replace( $personName, ' ', '' ) ) ][ 1 ]
        /DOWNLOAD__URL/text()
    )
    else(
      $fileList
        [ contains( NAME/text(), 'Заглушка' ) ]
        /DOWNLOAD__URL/text()
    )
   
  let $picture := 
    fetch:binary( $pictureURL )
  return
    xs:string( $picture )
};

(: старый варинат :)
declare function content:getContentFileData( $fileList, $name ){
  if( count( $name ) > 0 )
  then(
     let $currentName := string-join( $name, '_' )
     let $result := $fileList[ NAME/contains( ., $currentName ) ][ 1 ]
     return
       if( $result )
       then ( $result )
       else( content:getContentFileData( $fileList, $name[ position() < last() ] ) )
  )
  else()
};

(: исправленный вариант - работает :)
declare function  content:getContentFileData2( $fileList, $name ){
  let $currentName := string-join( $name, '_' ) || '_содержание.docx'
  let $r := $fileList[  NAME/text()  =  $currentName ]
    return
    if( count( $name ) > 0 )
    then(
      if( $r )
      then( $r[1] )
      else( content:getContentFileData2( $fileList, $name[ position() < last() ] ) )
    )
    else()
};

declare function content:getContentFile( $discName ){
  let $list := 
    rup:getFileContentList( '46686' )
      [ TYPE='file' ]
      [ NAME/ends-with( ., '_содержание.docx' ) ]
  
  let $d := functx:replace-multi( $discName[1], ( ':' ), ( '.' ) )
  let $contentFileURL := 
    content:getContentFileData2( $list, ( $d, $discName[ position() > 1 ] ) )/DOWNLOAD__URL/text()
  return
    if( $contentFileURL )
    then(
      fetch:binary( $contentFileURL )
    )
    else()
};