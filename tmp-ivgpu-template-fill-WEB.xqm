module namespace ivgpu = 'ivgpu';

import module namespace 
  rup = 'subjects.Department.Direction' 
    at 'tmp-ivgpu-discipliny-po-rupam-WEB.xqm';

declare namespace w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";

declare variable $ivgpu:contentFileFlag := '_содержание.docx';
declare variable $ivgpu:separator := '_';

declare 
  %rest:path( '/sandbox/ivgpu/templates/fill/{$rupID}/{$discID}' )
function ivgpu:main( $rupID, $discID ){
 
  let $templateFolderID := '46180'
  
  let $rupURL :=
    $rup:getList(
      $rup:folderList( $rupID )
    )[ ends-with( NAME/text(), '.xml' ) ][ 1 ]
    
  let $rup := fetch:xml( $rupURL/DOWNLOAD__URL/text() )
  let $disc := $rup//СтрокиПлана/Строка[ @ИдетификаторДисциплины/data() = $discID ]
  
  let $contentFileName :=
    $disc/@Дис/data() || '_' ||  normalize-space( $rup//Титул/@ПоследнийШифр/data() )
  
  let $data := 
    <table>
      <row id='tables'>
        {
          ivgpu:subjectContent(
          $contentFileName,
            ( 'Задачи', 'Результаты', 'Содержание' )
          ),
          <cell id='Компетенции'>
            <table>
              {
                for $i in tokenize( $disc/@КомпетенцииКоды, '&amp;' )
                where $i
                let $comp := $rup//Компетенции/Строка[ @Код = $i ]
                return
                  <row>
                    <cell>{
                      '- ' || $comp/@Индекс/data() || 
                      ' - ' || $comp/@Содержание/data() || ';'
                    }</cell>
                  </row>
              }
            </table>
          </cell>
        }
      </row>
      <row id='fields'>
        <cell id="Цели" contentType = "field">
          {
            ivgpu:subjectContent(
              $contentFileName,
              ( 'Цели' )
            )[ 1 ]//cell/text()
          }
        </cell>
        <cell id="Автор" contentType = "field">
          {
            ivgpu:subjectContent(
               $contentFileName,
              ( 'Автор' )
            )[ 1 ]//cell/text()
          }
        </cell>
        <cell id="Заведующий" contentType = "field">
          {
            ivgpu:subjectContent(
              $contentFileName,
              ( 'Заведующий' )
            )[ 1 ]//cell/text()
          }
        </cell>
        <cell id="Дисциплина" contentType = "field">
          { $rup//СтрокиПлана/Строка[ @ИдетификаторДисциплины/data() = $discID ]/@Дис/data() }
        </cell>
        <cell id="Направление" contentType = "field">
          { substring-after( $rup//Специальности/Специальность[ 1 ]/@Название/data(), ' ') }
        </cell>
        <cell id="Профиль" contentType = "field">
          {
            if(
                $rup//Специальности/Специальность[ 2 ]/@Название/data() != ''
              )
              then(
                substring-after( $rup//Специальности/Специальность[ 2 ]/@Название/data(), 'Профиль ')
              )
              else()
          }
        </cell>
        </row>
    </table>
  
  let $templatePath := 
    $rup:getList( $rup:folderList( $templateFolderID ) )
      [TYPE='file']
      [
        substring-before( NAME/text(), $ivgpu:separator ) = 'Аннотация' and 
        substring-after( NAME/text(), $ivgpu:separator ) = $rup//Титул/@ГодНачалаПодготовки/data() || '.docx'
      ]
 
  let $template := fetch:binary( $templatePath/DOWNLOAD__URL/text() )
  
  let $request :=
    <http:request method='post'>
      <http:multipart media-type = "multipart/form-data" >
          <http:header name="Content-Disposition" value= 'form-data; name="template";'/>
          <http:body media-type = "application/octet-stream" >
            { $template }
          </http:body>
          <http:header name="Content-Disposition" value= 'form-data; name="data";'/>
          <http:body media-type = "application/xml">
            { $data }
          </http:body>
      </http:multipart> 
    </http:request>
  
  let $ContentDispositionValue := "attachment; filename=" || 'titul24.docx'
  let $response := 
   http:send-request (
      $request,
      'http://localhost:8984/api/v1/ooxml/docx/template/complete'
    )
  return 
   (
      <rest:response>
        <http:response status="200">
          <http:header name="Content-Disposition" value="{ $ContentDispositionValue }" />
          <http:header name="Content-type" value="application/octet-stream"/>
        </http:response>
      </rest:response>,
      $response[2]
    )
};

declare function ivgpu:subjectContent( $disc, $fields ){
  
  let $contentBinary := ivgpu:getData( $disc )
  return
    if( $contentBinary instance of xs:base64Binary )
    then(
        let $data := 
          parse-xml ( 
              archive:extract-text( $contentBinary,  'word/document.xml' )
          )/w:document//w:tbl[ 1 ]
        let $cell := 
          function( $data, $id ){
            <cell id = '{ $id }'>
              <table>
                {
                  for $c in $data//w:tr[ w:tc[ 1 ][ w:p//w:t/text() = $id ] ]/w:tc[2 ]/w:p
                  return
                    <row>
                      <cell>{
                        string-join( $c//w:t/text() )
                      }</cell>
                    </row> 
                }
              </table>
            </cell>
          }
        
        for $r in $fields
        return
          $cell( $data, $r )
      )
      else()
};

declare function ivgpu:getData( $disc ){
  let $urlList := 'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' 
  let $getList := function( $id ){
    json:parse(
     fetch:text( $urlList || $id )
  )/json/result/_
  }

let $dataURL :=
  let $fileList := rup:getFileContentList( '46686' )[ TYPE='file' ]
  return
    if( $fileList[ substring-before( NAME/text(), $ivgpu:contentFileFlag ) = $disc ] )
    then(
       $fileList
        [
          substring-before( NAME/text(), $ivgpu:contentFileFlag ) = $disc 
        ]/DOWNLOAD__URL/text()
    )
    else(
      if(
        $fileList[
            substring-before( NAME/text(), $ivgpu:contentFileFlag )
          = substring-before( $disc, $ivgpu:separator )
        ]
      )
      then(
        $fileList[
            substring-before( NAME/text(), $ivgpu:contentFileFlag )
          = substring-before( $disc, $ivgpu:separator )
        ]/DOWNLOAD__URL/text()
      )
      else(false() )
    )
   

return
  if( $dataURL )
  then( fetch:binary( $dataURL ) )
  else( false() )
};