module namespace ivgpu = 'ivgpu';

declare namespace w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";

declare 
  %rest:path( '/sandbox/ivgpu/templates/fill/{$rupID}/{$discID}' )
function ivgpu:main( $rupID, $discID ){
 let $templateFolderID := '46180'
 let $urlList := 'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' 
  let $getList := function( $id ){
    json:parse(
     fetch:text( $urlList || $id )
  )/json/result/_
  }
  
  let $rupURL := 
    json:parse(
     fetch:text( 'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' || $rupID )
  )/json/result/_[ ends-with( NAME/text(), '.xml' ) ][1]
  
  let $rup := fetch:xml( $rupURL/DOWNLOAD__URL/text() )
  let $disc := $rup//СтрокиПлана/Строка[@ИдетификаторДисциплины/data()= $discID ]
  let $data := 
    <table>
      <row id='tables'>
        {
          ivgpu:t(
            $rup//СтрокиПлана/Строка[ @ИдетификаторДисциплины/data() = $discID ]/@Дис/data(),
            ( 'Задачи', 'Результаты', 'Содержание' )
          )
        }
      </row>
      <row id='fields'>
        <cell id="Цели" contentType = "field">
          {
            ivgpu:t(
              $rup//СтрокиПлана/Строка[ @ИдетификаторДисциплины/data() = $discID ]/@Дис/data(),
              ( 'Цели' )
            )[ 1 ]//cell/text()
          }
        </cell>
        <cell id="Автор" contentType = "field">
          {
            ivgpu:t(
              $rup//СтрокиПлана/Строка[ @ИдетификаторДисциплины/data() = $discID ]/@Дис/data(),
              ( 'Автор' )
            )[ 1 ]//cell/text()
          }
        </cell>
        <cell id="Заведующий" contentType = "field">
          {
            ivgpu:t(
              $rup//СтрокиПлана/Строка[ @ИдетификаторДисциплины/data() = $discID ]/@Дис/data(),
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
         <cell id="Компетенции" contentType = "field">
             {
              for $i in tokenize( $disc/@КомпетенцииКоды, '&amp;' )
              where $i
              return
                '- ' || $rup//Компетенции/Строка[ @Код = $i ]/@Индекс/data() || ' - ' ||
                $rup//Компетенции/Строка[ @Код = $i ]/@Содержание/data() || ';'
             }
         </cell>
        </row>
    </table>
  
  let $templatePath := 
    $getList( $templateFolderID )
      [TYPE='file']
      [
        substring-before( NAME/text(), '-') = 'Аннотация' and 
        substring-after( NAME/text(), '-') = $rup//Титул/@ГодНачалаПодготовки/data() || '.docx'
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

declare function ivgpu:t( $disc, $fields ){
  
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
  $getList('46686')[ TYPE='file' ]
    [
      substring-before( NAME/text(), '-') = $disc 
    ]/DOWNLOAD__URL/text()

return
  if( $dataURL )
  then( fetch:binary( $dataURL ) )
  else( false() )
  
};