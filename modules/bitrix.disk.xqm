module namespace bitrix.disk = 'bitrix.disk';

import module namespace 
  ooxml = 'ooxml' at 'ooxml.xqm';

declare function bitrix.disk:folderList( $id ){ 
    'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' || $id
  };

declare function bitrix.disk:getList ( $url )
{
  json:parse( fetch:text( $url ) )/json/result/_
};

declare function bitrix.disk:getFileList( $folderID, $params ){
  let $list := 
    bitrix.disk:getList( bitrix.disk:folderList( $folderID ) )
  let $mask := 
    if( $params?name )then( $params?name )else( '.' )
  return
     (
       $list[ TYPE = 'file' ][ matches( NAME/text(), $mask ) ],
       if( $params?recursive = 'yes' )
       then(
         for $f in $list[ TYPE = 'folder' ]
         return
           bitrix.disk:getFileList( $f/ID/text(), $params )
       )
       else()       
     ) 
};

declare function bitrix.disk:getFileList( $folderID ){
   bitrix.disk:getFileList( $folderID, map{} )
};

declare function bitrix.disk:getFileBinary( $folderID, $params ){
  let $filesList := 
    bitrix.disk:getFileList( $folderID, $params )
  for $i in $filesList
  return
    fetch:binary( $i/DOWNLOAD__URL/text() )
};

declare function bitrix.disk:getFileXLSX( $folderID, $params ){
  let $xlsxBinary :=
    bitrix.disk:getFileBinary( $folderID,  $params )
  return
    ooxml:parse.workbook( $xlsxBinary )
};