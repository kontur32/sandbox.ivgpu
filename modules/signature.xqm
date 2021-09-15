module namespace signature = 'simplex/signature';

import module namespace 
  bitrix.disk = 'bitrix.disk' 
    at 'bitrix.disk.xqm';

declare function signature:подписатьФайл(
  $полноеИмяФайла,
  $идентификаторСубъекта,
  $секрет,
  $путьХранилищаПодписей
)
{
  let $signature :=
    signature:создатьПодписьОбъекта( $полноеИмяФайла, $идентификаторСубъекта, $секрет ) 
  let $хэшИдентификатораПользователя := web:encode-url( $идентификаторСубъекта )
  let $хэшПолногоИмениФайла := string( xs:hexBinary( hash:sha256( $полноеИмяФайла ) ) )
  
  let $полноеИмяФайлаПодписи := 
    $путьХранилищаПодписей ||
    $хэшПолногоИмениФайла || '/' || $хэшИдентификатораПользователя || '.sig'
  return
      if( bitrix.disk:fileExists( $полноеИмяФайлаПодписи ) )
      then(
        bitrix.disk:fileReplace( $полноеИмяФайлаПодписи, $signature )
        /response/result/ID/text()
      )
      else(
        bitrix.disk:fileUpload( $полноеИмяФайлаПодписи,  $signature ),
        bitrix.disk:fileReplace( $полноеИмяФайлаПодписи, $signature )
        /response/result/ID/text()
      ) 
};

declare function signature:создатьПодписьОбъекта( $полноеИмяФайла, $идентификаторСубъекта, $секрет ){
  let $файл := bitrix.disk:getFile( $полноеИмяФайла )
  return
    signature:создатьПодписьФайла( $файл, $идентификаторСубъекта, $секрет )
};

declare function signature:создатьПодписьФайла( $файл, $идентификаторСубъекта, $секрет ){
  crypto:hmac(
      string( hash:sha256( $файл ) ) || $идентификаторСубъекта,
      $секрет,
      'sha256'
    )
};

declare function signature:проверитьПодпись(
  $полноеИмяФайла,
  $идентификаторСубъекта,
  $секрет,
  $подпись as xs:base64Binary
)
{
  let $хэшИдентификатораПользователя := web:encode-url( $идентификаторСубъекта )
  let $хэшПолногоИмениФайла := string( xs:hexBinary( hash:sha256( $полноеИмяФайла ) ) )
  return
     signature:создатьПодписьОбъекта( $полноеИмяФайла, $идентификаторСубъекта, $секрет ) = 
     xs:string( $подпись )
};

declare
function
  signature:проверитьПодписьОбъекта(
    $полноеИмяФайла,
    $идентификаторСубъекта,
    $секрет,
    $путьХранилищаПодписей
  )
{
    let $хэшИдентификатораПользователя := web:encode-url( $идентификаторСубъекта )
    let $хэшПолногоИмениФайла := string( xs:hexBinary( hash:sha256( $полноеИмяФайла ) ) )
    
    let $полноеИмяФайлаПодписи := 
      $путьХранилищаПодписей ||
      $хэшПолногоИмениФайла || '/' || $хэшИдентификатораПользователя || '.sig'
     return
       signature:создатьПодписьОбъекта( $полноеИмяФайла, $идентификаторСубъекта, $секрет ) = 
        
        xs:string( bitrix.disk:getFile(  $полноеИмяФайлаПодписи ) )
};

declare
function
  signature:найтиПодписиОбъекта(
    $полноеИмяФайла,
    $секрет,
    $путьХранилищаПодписей
  )
{
  let $путьПодписи := 
    $путьХранилищаПодписей || string( xs:hexBinary( hash:sha256( $полноеИмяФайла ) ) )
  
  let $подписи :=
      bitrix.disk:getFileList( bitrix.disk:getFolderID( $путьПодписи ), map{ 'name' : '.sig$'} )
  for $i in $подписи
  let $идентификаторСубъекта := substring-before( web:decode-url( $i[ 1 ]/NAME/text() ), '.sig' )
  let $подпись := fetch:binary( $i[ 1 ]/DOWNLOAD__URL/text() ) 
  let $проверкаПодписи := 
    signature:проверитьПодпись(
      $полноеИмяФайла,
      $идентификаторСубъекта, 
      $секрет,
      $подпись
    )
  return
    if( $проверкаПодписи )
    then( $идентификаторСубъекта )
    else()
};
